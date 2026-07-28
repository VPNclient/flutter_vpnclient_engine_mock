import '../subscription.dart';
import 'subscription_store.dart';

/// A [SubscriptionStore] with no disk/plugin dependency, for tests.
class InMemorySubscriptionStore implements SubscriptionStore {
  List<Subscription> _subscriptions = const [];

  @override
  Future<List<Subscription>> load() async => List.of(_subscriptions);

  @override
  Future<void> save(List<Subscription> subscriptions) async {
    _subscriptions = List.of(subscriptions);
  }
}
