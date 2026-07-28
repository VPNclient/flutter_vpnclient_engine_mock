import 'dart:convert';

import '../../config/protocol_config.dart';
import '../../config/tls_config.dart';
import '../../config/transport_config.dart';
import '../id_generator.dart';
import '../server.dart';
import '../server_definition.dart';
import '../subscription_parser.dart';

/// A whole-document sing-box config JSON — reads its `outbounds` array,
/// mapping each supported outbound (`vless`/`vmess`/`trojan`/`shadowsocks`/
/// `wireguard`) into a [ProtocolConfig]; unsupported outbound types
/// (`direct`, `block`, `dns`, ...) are skipped.
class SingBoxConfigParser extends SubscriptionParser {
  const SingBoxConfigParser();

  @override
  bool canParse(String rawBody) {
    final trimmed = rawBody.trim();
    if (!trimmed.startsWith('{')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is Map<String, dynamic> && decoded['outbounds'] is List;
    } catch (_) {
      return false;
    }
  }

  @override
  List<Server> parse(String rawBody) {
    final decoded = jsonDecode(rawBody.trim()) as Map<String, dynamic>;
    final outbounds = (decoded['outbounds'] as List<dynamic>).cast<Map<String, dynamic>>();
    final servers = <Server>[];
    for (final outbound in outbounds) {
      final config = _toProtocolConfig(outbound);
      if (config == null) continue;
      servers.add(Server(
        id: generateId('srv'),
        name: (outbound['tag'] as String?) ?? config.address,
        definition: FullConfigDefinition(config),
      ));
    }
    return servers;
  }

  ProtocolConfig? _toProtocolConfig(Map<String, dynamic> outbound) {
    final server = outbound['server'] as String?;
    final port = outbound['server_port'] as int?;
    if (server == null || port == null) return null;

    final transport = _transportOf(outbound['transport'] as Map<String, dynamic>?);
    final tls = _tlsOf(outbound['tls'] as Map<String, dynamic>?, server);

    return switch (outbound['type']) {
      'vless' => VlessConfig(
          address: server,
          port: port,
          uuid: outbound['uuid'] as String,
          flow: outbound['flow'] as String?,
          transport: transport,
          tls: tls,
        ),
      'vmess' => VmessConfig(
          address: server,
          port: port,
          uuid: outbound['uuid'] as String,
          alterId: (outbound['alter_id'] as int?) ?? 0,
          transport: transport,
          tls: tls,
        ),
      'trojan' => TrojanConfig(
          address: server,
          port: port,
          password: outbound['password'] as String,
          transport: transport,
          tls: tls,
        ),
      'shadowsocks' => ShadowsocksConfig(
          address: server,
          port: port,
          method: outbound['method'] as String,
          password: outbound['password'] as String,
        ),
      'wireguard' => WireGuardConfig(
          address: server,
          port: port,
          publicKey: outbound['peer_public_key'] as String? ?? '',
          privateKey: outbound['private_key'] as String? ?? '',
          allowedIps:
              (outbound['allowed_ips'] as List<dynamic>?)?.cast<String>() ??
                  const ['0.0.0.0/0'],
        ),
      _ => null,
    };
  }

  TransportConfig? _transportOf(Map<String, dynamic>? transportJson) {
    if (transportJson == null) return null;
    final headers = transportJson['headers'] as Map<String, dynamic>?;
    return TransportConfig(
      type: switch (transportJson['type']) {
        'ws' => TransportType.ws,
        'grpc' => TransportType.grpc,
        'http' || 'http2' => TransportType.http2,
        _ => TransportType.tcp,
      },
      path: transportJson['path'] as String?,
      host: headers?['Host'] as String?,
      serviceName: transportJson['service_name'] as String?,
    );
  }

  TlsConfig? _tlsOf(Map<String, dynamic>? tlsJson, String fallbackSni) {
    if (tlsJson == null || tlsJson['enabled'] != true) return null;
    final realityJson = tlsJson['reality'] as Map<String, dynamic>?;
    RealityConfig? reality;
    if (realityJson != null && realityJson['enabled'] == true) {
      reality = RealityConfig(
        publicKey: realityJson['public_key'] as String,
        shortId: realityJson['short_id'] as String,
      );
    }
    return TlsConfig(
      sni: (tlsJson['server_name'] as String?) ?? fallbackSni,
      alpn: (tlsJson['alpn'] as List<dynamic>?)?.cast<String>() ?? const [],
      reality: reality,
    );
  }
}
