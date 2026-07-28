import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/storage/in_memory_subscription_store.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription_manager.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription_parse_exception.dart';

http.Client _mockClientReturning(String body) {
  return MockClient((request) async => http.Response(body, 200));
}

void main() {
  test('refreshSubscription on a local subscription throws StateError', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addLocalSubscription(name: 'Local');

    expect(() => manager.refreshSubscription(sub.id), throwsStateError);
  });

  test('addServer/updateServer/removeServer on a remote subscription throw StateError', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );

    expect(
      () => manager.addServer(sub.id, const ShareLinkDefinition('ss://x@host:1#r')),
      throwsStateError,
    );
    expect(
      () => manager.updateServer(sub.id, 'whatever', const ShareLinkDefinition('ss://x@host:1#r')),
      throwsStateError,
    );
    expect(() => manager.removeServer(sub.id, 'whatever'), throwsStateError);
  });

  test('refreshSubscription fetches, parses, replaces servers, and persists', () async {
    final shareLine = 'ss://${base64Encode(utf8.encode('aes-256-gcm:secret'))}@ss.example.com:8388#Remote-SS';
    final body = base64Encode(utf8.encode(shareLine));

    final manager = SubscriptionManager(
      store: InMemorySubscriptionStore(),
      httpClient: _mockClientReturning(body),
    );
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );
    expect(sub.servers, isEmpty);

    await manager.refreshSubscription(sub.id);

    final refreshed = manager.subscriptions.firstWhere((s) => s.id == sub.id);
    expect(refreshed.servers, hasLength(1));
    expect(refreshed.servers.single.name, 'Remote-SS');
    expect(refreshed.lastUpdatedAt, isNotNull);
  });

  test('malformed body throws SubscriptionParseException without mutating state', () async {
    final manager = SubscriptionManager(
      store: InMemorySubscriptionStore(),
      httpClient: _mockClientReturning('not a valid subscription body at all'),
    );
    final sub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );

    await expectLater(
      () => manager.refreshSubscription(sub.id),
      throwsA(isA<SubscriptionParseException>()),
    );

    final unchanged = manager.subscriptions.firstWhere((s) => s.id == sub.id);
    expect(unchanged.servers, isEmpty);
    expect(unchanged.lastUpdatedAt, isNull);
  });

  test('cloneServerTo survives a subsequent refresh of the original remote subscription', () async {
    final shareLine = 'ss://${base64Encode(utf8.encode('aes-256-gcm:secret'))}@ss.example.com:8388#Remote-SS';
    final body = base64Encode(utf8.encode(shareLine));

    final manager = SubscriptionManager(
      store: InMemorySubscriptionStore(),
      httpClient: _mockClientReturning(body),
    );
    final remoteSub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );
    await manager.refreshSubscription(remoteSub.id);
    final originalServer =
        manager.subscriptions.firstWhere((s) => s.id == remoteSub.id).servers.single;

    final localSub = await manager.addLocalSubscription(name: 'My edits');
    final clone = await manager.cloneServerTo(
      originalServer.id,
      targetLocalSubscriptionId: localSub.id,
    );
    expect(clone.id, isNot(originalServer.id));
    expect(clone.name, originalServer.name);

    // Refresh the original again — a fresh mock response is fine, same body.
    await manager.refreshSubscription(remoteSub.id);

    final localAfterRefresh =
        manager.subscriptions.firstWhere((s) => s.id == localSub.id);
    expect(localAfterRefresh.servers, contains(clone));
  });

  test('cloneServerTo into a remote target subscription is rejected', () async {
    final manager = SubscriptionManager(store: InMemorySubscriptionStore());
    final localSub = await manager.addLocalSubscription(name: 'Local');
    final server = await manager.addServer(
      localSub.id,
      const ShareLinkDefinition('ss://x@host:1#r'),
      name: 'Placeholder',
    );
    final remoteSub = await manager.addRemoteSubscription(
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
    );

    expect(
      () => manager.cloneServerTo(server.id, targetLocalSubscriptionId: remoteSub.id),
      throwsStateError,
    );
  });
}
