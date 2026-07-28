import 'dart:async';

import 'package:http/http.dart' as http;

import 'id_generator.dart';
import 'parsers/json_array_parser.dart';
import 'parsers/share_link_list_parser.dart';
import 'parsers/sing_box_config_parser.dart';
import 'server.dart';
import 'server_definition.dart';
import 'storage/subscription_store.dart';
import 'subscription.dart';
import 'subscription_parse_exception.dart';
import 'subscription_parser.dart';

/// Owns `List<Subscription>`, each owning `List<Server>`; fetching, parsing,
/// and **persisting** them entirely inside the engine — the app never
/// performs an HTTP request, base64 decode, share-link parse, or
/// persistence read/write itself.
///
/// Plain constructible instance — no forced global singleton.
class SubscriptionManager {
  SubscriptionManager({
    required SubscriptionStore store,
    List<SubscriptionParser> parsers = const [
      ShareLinkListParser(),
      JsonArrayParser(),
      SingBoxConfigParser(),
    ],
    http.Client? httpClient,
  })  : _store = store,
        _parsers = parsers,
        _httpClient = httpClient ?? http.Client() {
    _ready = _load();
  }

  final SubscriptionStore _store;
  final List<SubscriptionParser> _parsers;
  final http.Client _httpClient;

  late final Future<void> _ready;

  /// Completes once the initial [SubscriptionStore.load] has finished.
  Future<void> get ready => _ready;

  List<Subscription> _subscriptions = [];
  final _subscriptionsController = StreamController<List<Subscription>>.broadcast();

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  Stream<List<Subscription>> get subscriptionsStream => _subscriptionsController.stream;

  Future<void> _load() async {
    _subscriptions = await _store.load();
    _subscriptionsController.add(subscriptions);
  }

  Future<void> _persist() async {
    await _store.save(_subscriptions);
    _subscriptionsController.add(subscriptions);
  }

  // Serializes mutations so concurrent calls don't race on a read-modify-write
  // of the full subscriptions list — one in-flight save at a time.
  Future<void> _lock = Future.value();

  Future<T> _guarded<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  // --- Subscription CRUD ---

  Future<Subscription> addRemoteSubscription({
    required String name,
    required Uri url,
    Duration? refreshInterval,
  }) {
    return _guarded(() async {
      await ready;
      final subscription = Subscription(
        id: generateId('sub'),
        name: name,
        url: url,
        refreshInterval: refreshInterval,
        servers: const [],
      );
      _subscriptions = [..._subscriptions, subscription];
      await _persist();
      return subscription;
    });
  }

  Future<Subscription> addLocalSubscription({required String name}) {
    return _guarded(() async {
      await ready;
      final subscription = Subscription(
        id: generateId('sub'),
        name: name,
        url: null,
        servers: const [],
      );
      _subscriptions = [..._subscriptions, subscription];
      await _persist();
      return subscription;
    });
  }

  Future<void> removeSubscription(String id) {
    return _guarded(() async {
      await ready;
      _subscriptions = _subscriptions.where((s) => s.id != id).toList();
      await _persist();
    });
  }

  Future<void> renameSubscription(String id, String name) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(id);
      final updated = List.of(_subscriptions);
      updated[index] = updated[index].copyWith(name: name);
      _subscriptions = updated;
      await _persist();
    });
  }

  // --- Refresh (remote subscriptions only) ---

  Future<void> refreshSubscription(String id) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(id);
      final subscription = _subscriptions[index];
      if (subscription.isLocal) {
        throw StateError('Subscription is local; nothing to fetch');
      }

      final response = await _httpClient.get(subscription.url!);
      final body = response.body;
      final parser = _parsers.firstWhere(
        (p) => p.canParse(body),
        orElse: () =>
            throw SubscriptionParseException('No parser recognized the subscription body'),
      );
      final servers = parser.parse(body);

      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: servers, lastUpdatedAt: DateTime.now());
      _subscriptions = updated;
      await _persist();
    });
  }

  /// Refreshes every remote subscription; local subscriptions are skipped
  /// silently (there is nothing to fetch).
  Future<void> refreshAll() async {
    await ready;
    for (final subscription in List.of(_subscriptions)) {
      if (subscription.isLocal) continue;
      await refreshSubscription(subscription.id);
    }
  }

  // --- Server CRUD (local subscriptions only) ---

  Future<Server> addServer(
    String subscriptionId,
    ServerDefinition definition, {
    String? name,
  }) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final server = Server(
        id: generateId('srv'),
        name: name ?? definition.resolve().address,
        definition: definition,
      );
      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: [...subscription.servers, server]);
      _subscriptions = updated;
      await _persist();
      return server;
    });
  }

  Future<void> updateServer(
    String subscriptionId,
    String serverId,
    ServerDefinition definition,
  ) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final serverIndex = subscription.servers.indexWhere((s) => s.id == serverId);
      if (serverIndex == -1) {
        throw ArgumentError('No server with id $serverId in subscription $subscriptionId');
      }
      final updatedServers = List.of(subscription.servers);
      updatedServers[serverIndex] = updatedServers[serverIndex].copyWith(definition: definition);

      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: updatedServers);
      _subscriptions = updated;
      await _persist();
    });
  }

  Future<void> removeServer(String subscriptionId, String serverId) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final updatedServers = subscription.servers.where((s) => s.id != serverId).toList();
      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: updatedServers);
      _subscriptions = updated;
      await _persist();
    });
  }

  /// Copies a server (from any subscription, remote or local) into a local
  /// subscription so it becomes independently editable — surviving a
  /// subsequent refresh of the original subscription, since the clone lives
  /// in a different subscription's server list under a new id.
  Future<Server> cloneServerTo(
    String serverId, {
    required String targetLocalSubscriptionId,
  }) {
    return _guarded(() async {
      await ready;
      Server? found;
      for (final subscription in _subscriptions) {
        for (final server in subscription.servers) {
          if (server.id == serverId) {
            found = server;
            break;
          }
        }
        if (found != null) break;
      }
      if (found == null) {
        throw ArgumentError('No server with id $serverId');
      }

      final targetIndex = _indexOfSubscriptionOrThrow(targetLocalSubscriptionId);
      final target = _requireLocal(_subscriptions[targetIndex]);

      final clone = Server(id: generateId('srv'), name: found.name, definition: found.definition);
      final updated = List.of(_subscriptions);
      updated[targetIndex] = target.copyWith(servers: [...target.servers, clone]);
      _subscriptions = updated;
      await _persist();
      return clone;
    });
  }

  int _indexOfSubscriptionOrThrow(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) throw ArgumentError('No subscription with id $id');
    return index;
  }

  Subscription _requireLocal(Subscription subscription) {
    if (!subscription.isLocal) {
      throw StateError(
        'Cannot directly edit servers of a remote subscription; use cloneServerTo() instead',
      );
    }
    return subscription;
  }

  Future<void> dispose() async {
    await _subscriptionsController.close();
    _httpClient.close();
  }
}
