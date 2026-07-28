import 'server.dart';

/// Recognizes and parses one subscription body format into a `List<Server>`.
///
/// New formats plug in by implementing this and registering an instance with
/// `SubscriptionManager`, without changing its public API.
abstract class SubscriptionParser {
  const SubscriptionParser();

  bool canParse(String rawBody);

  List<Server> parse(String rawBody);
}
