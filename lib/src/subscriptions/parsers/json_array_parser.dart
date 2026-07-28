import 'dart:convert';

import '../../config/protocol_config.dart';
import '../id_generator.dart';
import '../server.dart';
import '../server_definition.dart';
import '../subscription_parser.dart';

/// A whole-document JSON array of full per-server descriptions (using this
/// package's [ProtocolConfig.toJson] schema, each optionally tagged with a
/// `name`).
class JsonArrayParser extends SubscriptionParser {
  const JsonArrayParser();

  @override
  bool canParse(String rawBody) {
    final trimmed = rawBody.trim();
    if (!trimmed.startsWith('[')) return false;
    try {
      return jsonDecode(trimmed) is List;
    } catch (_) {
      return false;
    }
  }

  @override
  List<Server> parse(String rawBody) {
    final decoded = jsonDecode(rawBody.trim()) as List<dynamic>;
    return decoded.map((entry) {
      final json = entry as Map<String, dynamic>;
      final config = ProtocolConfig.fromJson(json);
      return Server(
        id: generateId('srv'),
        name: (json['name'] as String?) ?? config.address,
        definition: FullConfigDefinition(config),
      );
    }).toList();
  }
}
