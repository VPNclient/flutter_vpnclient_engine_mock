import 'dart:convert';

import '../../config/protocol_config.dart';
import '../id_generator.dart';
import '../server.dart';
import '../server_definition.dart';
import '../subscription_parser.dart';

/// The classic v2ray/xray subscription format: base64-encoded, newline
/// separated entries.
///
/// Each line is independently sniffed — either a share-link
/// (`vless://`, `vmess://`, `trojan://`, `ss://`) or a full JSON object
/// describing that one server (using this package's [ProtocolConfig.toJson]
/// schema) — so a single subscription can mix both per-server authoring
/// styles, per anton's correction that "not only via config" but full JSON
/// per server must be supported inside this same classic list.
class ShareLinkListParser extends SubscriptionParser {
  const ShareLinkListParser();

  static const _schemes = ['vless://', 'vmess://', 'trojan://', 'ss://'];

  @override
  bool canParse(String rawBody) {
    final decoded = _tryDecodeBase64(rawBody.trim());
    if (decoded == null) return false;
    final lines = _nonEmptyLines(decoded);
    if (lines.isEmpty) return false;
    return lines.every(
      (line) => _schemes.any(line.startsWith) || _looksLikeJsonObject(line),
    );
  }

  @override
  List<Server> parse(String rawBody) {
    final decoded = _tryDecodeBase64(rawBody.trim());
    if (decoded == null) {
      throw const FormatException('Not a base64-encoded share-link list');
    }
    return _nonEmptyLines(decoded).map(_parseLine).toList();
  }

  Server _parseLine(String line) {
    if (_looksLikeJsonObject(line)) {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final config = ProtocolConfig.fromJson(json);
      return Server(
        id: generateId('srv'),
        name: (json['name'] as String?) ?? config.address,
        definition: FullConfigDefinition(config),
      );
    }
    final uri = Uri.parse(line);
    final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : uri.host;
    return Server(
      id: generateId('srv'),
      name: name,
      definition: ShareLinkDefinition(line),
    );
  }

  List<String> _nonEmptyLines(String decoded) => decoded
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  bool _looksLikeJsonObject(String line) => line.startsWith('{') && line.endsWith('}');

  String? _tryDecodeBase64(String input) {
    try {
      var normalized = input
          .replaceAll('-', '+')
          .replaceAll('_', '/')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll(' ', '');
      final remainder = normalized.length % 4;
      if (remainder != 0) {
        normalized += '=' * (4 - remainder);
      }
      return utf8.decode(base64.decode(normalized));
    } catch (_) {
      return null;
    }
  }
}
