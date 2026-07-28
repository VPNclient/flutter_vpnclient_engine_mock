/// Thrown when no registered `SubscriptionParser` recognizes a fetched
/// subscription body.
class SubscriptionParseException implements Exception {
  SubscriptionParseException(this.message);

  final String message;

  @override
  String toString() => 'SubscriptionParseException: $message';
}
