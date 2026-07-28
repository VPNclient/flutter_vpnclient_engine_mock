import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'transport_config.dart';
import 'tls_config.dart';

/// A server's connection parameters, one concrete variant per protocol.
///
/// Deliberately not one flat class with every protocol's fields nullable —
/// a [WireGuardConfig] can't accidentally carry a VLESS `flow` field.
@immutable
sealed class ProtocolConfig {
  const ProtocolConfig({required this.address, required this.port});

  final String address;
  final int port;

  /// Parses an xray-style share-link (`vless://`, `vmess://`, `trojan://`,
  /// `ss://`) into the matching [ProtocolConfig] variant.
  ///
  /// Scoped to the fields this package's [ProtocolConfig] models — enough to
  /// validate structure and drive the mocked connection, not a byte-for-byte
  /// reimplementation of every real client's share-link dialect.
  static ProtocolConfig parseShareLink(String raw) {
    final scheme = raw.substring(0, raw.indexOf(':')).toLowerCase();
    return switch (scheme) {
      'vless' => _parseVless(Uri.parse(raw)),
      'vmess' => _parseVmess(raw),
      'trojan' => _parseTrojan(Uri.parse(raw)),
      'ss' => _parseShadowsocks(Uri.parse(raw)),
      _ => throw FormatException('Unsupported share-link scheme: $scheme'),
    };
  }

  /// Serializes to JSON, tagged with a `protocol` discriminator so
  /// [ProtocolConfig.fromJson] can dispatch back to the right variant.
  Map<String, dynamic> toJson();

  static ProtocolConfig fromJson(Map<String, dynamic> json) {
    return switch (json['protocol']) {
      'vless' => VlessConfig._fromJson(json),
      'vmess' => VmessConfig._fromJson(json),
      'trojan' => TrojanConfig._fromJson(json),
      'shadowsocks' => ShadowsocksConfig._fromJson(json),
      'wireguard' => WireGuardConfig._fromJson(json),
      _ => throw FormatException('Unknown protocol discriminator: ${json['protocol']}'),
    };
  }
}

@immutable
class VlessConfig extends ProtocolConfig {
  const VlessConfig({
    required super.address,
    required super.port,
    required this.uuid,
    this.flow,
    this.transport,
    this.tls,
  });

  final String uuid;
  final String? flow;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is VlessConfig &&
      other.address == address &&
      other.port == port &&
      other.uuid == uuid &&
      other.flow == flow &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode => Object.hash(address, port, uuid, flow, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'vless',
        'address': address,
        'port': port,
        'uuid': uuid,
        'flow': flow,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory VlessConfig._fromJson(Map<String, dynamic> json) {
    return VlessConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      uuid: json['uuid'] as String,
      flow: json['flow'] as String?,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class VmessConfig extends ProtocolConfig {
  const VmessConfig({
    required super.address,
    required super.port,
    required this.uuid,
    required this.alterId,
    this.transport,
    this.tls,
  });

  final String uuid;
  final int alterId;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is VmessConfig &&
      other.address == address &&
      other.port == port &&
      other.uuid == uuid &&
      other.alterId == alterId &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode =>
      Object.hash(address, port, uuid, alterId, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'vmess',
        'address': address,
        'port': port,
        'uuid': uuid,
        'alterId': alterId,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory VmessConfig._fromJson(Map<String, dynamic> json) {
    return VmessConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      uuid: json['uuid'] as String,
      alterId: json['alterId'] as int,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class TrojanConfig extends ProtocolConfig {
  const TrojanConfig({
    required super.address,
    required super.port,
    required this.password,
    this.transport,
    this.tls,
  });

  final String password;
  final TransportConfig? transport;
  final TlsConfig? tls;

  @override
  bool operator ==(Object other) =>
      other is TrojanConfig &&
      other.address == address &&
      other.port == port &&
      other.password == password &&
      other.transport == transport &&
      other.tls == tls;

  @override
  int get hashCode =>
      Object.hash(address, port, password, transport, tls);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'trojan',
        'address': address,
        'port': port,
        'password': password,
        'transport': transport?.toJson(),
        'tls': tls?.toJson(),
      };

  factory TrojanConfig._fromJson(Map<String, dynamic> json) {
    return TrojanConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      password: json['password'] as String,
      transport: json['transport'] != null
          ? TransportConfig.fromJson(json['transport'] as Map<String, dynamic>)
          : null,
      tls: json['tls'] != null
          ? TlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
          : null,
    );
  }
}

@immutable
class ShadowsocksConfig extends ProtocolConfig {
  const ShadowsocksConfig({
    required super.address,
    required super.port,
    required this.method,
    required this.password,
  });

  final String method;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is ShadowsocksConfig &&
      other.address == address &&
      other.port == port &&
      other.method == method &&
      other.password == password;

  @override
  int get hashCode => Object.hash(address, port, method, password);

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'shadowsocks',
        'address': address,
        'port': port,
        'method': method,
        'password': password,
      };

  factory ShadowsocksConfig._fromJson(Map<String, dynamic> json) {
    return ShadowsocksConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      method: json['method'] as String,
      password: json['password'] as String,
    );
  }
}

@immutable
class WireGuardConfig extends ProtocolConfig {
  const WireGuardConfig({
    required super.address,
    required super.port,
    required this.publicKey,
    required this.privateKey,
    this.presharedKey,
    required this.allowedIps,
  });

  final String publicKey;
  final String privateKey;
  final String? presharedKey;
  final List<String> allowedIps;

  static const _listEquality = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is WireGuardConfig &&
      other.address == address &&
      other.port == port &&
      other.publicKey == publicKey &&
      other.privateKey == privateKey &&
      other.presharedKey == presharedKey &&
      _listEquality.equals(other.allowedIps, allowedIps);

  @override
  int get hashCode => Object.hash(
        address,
        port,
        publicKey,
        privateKey,
        presharedKey,
        _listEquality.hash(allowedIps),
      );

  @override
  Map<String, dynamic> toJson() => {
        'protocol': 'wireguard',
        'address': address,
        'port': port,
        'publicKey': publicKey,
        'privateKey': privateKey,
        'presharedKey': presharedKey,
        'allowedIps': allowedIps,
      };

  factory WireGuardConfig._fromJson(Map<String, dynamic> json) {
    return WireGuardConfig(
      address: json['address'] as String,
      port: json['port'] as int,
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
      presharedKey: json['presharedKey'] as String?,
      allowedIps: (json['allowedIps'] as List<dynamic>).cast<String>(),
    );
  }
}

TransportType _parseTransportType(String? net) => switch (net) {
      'ws' => TransportType.ws,
      'grpc' => TransportType.grpc,
      'http2' || 'h2' => TransportType.http2,
      _ => TransportType.tcp,
    };

TransportConfig? _transportFromQuery(Map<String, String> query) {
  final type = _parseTransportType(query['type']);
  if (type == TransportType.tcp &&
      query['path'] == null &&
      query['host'] == null &&
      query['serviceName'] == null) {
    return null;
  }
  return TransportConfig(
    type: type,
    path: query['path'],
    host: query['host'],
    serviceName: query['serviceName'],
  );
}

TlsConfig? _tlsFromQuery(Map<String, String> query, String fallbackSni) {
  final security = query['security'];
  if (security != 'tls' && security != 'reality') return null;
  final alpn = query['alpn']?.split(',').where((s) => s.isNotEmpty).toList() ??
      const [];
  RealityConfig? reality;
  if (security == 'reality') {
    final publicKey = query['pbk'];
    final shortId = query['sid'];
    if (publicKey != null && shortId != null) {
      reality = RealityConfig(
        publicKey: publicKey,
        shortId: shortId,
        spiderX: query['spx'],
      );
    }
  }
  return TlsConfig(sni: query['sni'] ?? fallbackSni, alpn: alpn, reality: reality);
}

VlessConfig _parseVless(Uri uri) {
  final query = uri.queryParameters;
  return VlessConfig(
    address: uri.host,
    port: uri.port,
    uuid: uri.userInfo,
    flow: query['flow'],
    transport: _transportFromQuery(query),
    tls: _tlsFromQuery(query, uri.host),
  );
}

String _decodeBase64(String input) {
  var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  final remainder = normalized.length % 4;
  if (remainder != 0) {
    normalized += '=' * (4 - remainder);
  }
  return utf8.decode(base64.decode(normalized));
}

VmessConfig _parseVmess(String raw) {
  final payload = raw.substring('vmess://'.length);
  final decoded = jsonDecode(_decodeBase64(payload)) as Map<String, dynamic>;
  final net = decoded['net'] as String?;
  final transportType = _parseTransportType(net);
  final hasTransportDetails = decoded['path'] != null || decoded['host'] != null;
  final transport = (transportType == TransportType.tcp && !hasTransportDetails)
      ? null
      : TransportConfig(
          type: transportType,
          path: decoded['path'] as String?,
          host: decoded['host'] as String?,
        );
  final tlsField = decoded['tls'] as String?;
  final tls = (tlsField == 'tls' || tlsField == 'reality')
      ? TlsConfig(sni: (decoded['sni'] as String?) ?? decoded['add'] as String)
      : null;
  return VmessConfig(
    address: decoded['add'] as String,
    port: int.parse(decoded['port'].toString()),
    uuid: decoded['id'] as String,
    alterId: int.parse((decoded['aid'] ?? 0).toString()),
    transport: transport,
    tls: tls,
  );
}

TrojanConfig _parseTrojan(Uri uri) {
  final query = uri.queryParameters;
  return TrojanConfig(
    address: uri.host,
    port: uri.port,
    password: uri.userInfo,
    transport: _transportFromQuery(query),
    tls: _tlsFromQuery(query, uri.host) ?? TlsConfig(sni: uri.host),
  );
}

ShadowsocksConfig _parseShadowsocks(Uri uri) {
  final decoded = _decodeBase64(uri.userInfo);
  final separatorIndex = decoded.indexOf(':');
  return ShadowsocksConfig(
    address: uri.host,
    port: uri.port,
    method: decoded.substring(0, separatorIndex),
    password: decoded.substring(separatorIndex + 1),
  );
}
