import '../subscription.dart';

/// Persists the subscriptions/servers tree so it survives an app restart
/// unchanged.
///
/// This is the injection point for durable state: [SubscriptionManager]
/// depends on this abstraction, not a hardcoded concrete store, so tests can
/// supply [InMemorySubscriptionStore] and the app never touches storage
/// directly.
abstract class SubscriptionStore {
  Future<List<Subscription>> load();

  Future<void> save(List<Subscription> subscriptions);
}
