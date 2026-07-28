import 'package:vpnclient_engine/vpnclient_engine.dart';

Future<void> main() async {
  final engine = VpnEngine(
    capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
  );

  final subscriptions = SubscriptionManager(store: InMemorySubscriptionStore());
  await subscriptions.ready;
  final local = await subscriptions.addLocalSubscription(name: 'My servers');
  final server = await subscriptions.addServer(
    local.id,
    const FullConfigDefinition(
      ShadowsocksConfig(
        address: 'ss.example.com',
        port: 8388,
        method: 'aes-256-gcm',
        password: 'secret',
      ),
    ),
    name: 'Example server',
  );

  await engine.connect(server);
  assert(engine.state is Connected);

  await engine.disconnect();
  await engine.dispose();
  await subscriptions.dispose();
}
