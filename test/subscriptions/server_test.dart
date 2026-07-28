import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';
import 'package:vpnclient_engine/src/subscriptions/subscription.dart';

void main() {
  test('Server with a ShareLinkDefinition resolves protocolConfig via parsing', () {
    final server = Server(
      id: 's1',
      name: 'Share-link server',
      definition: const ShareLinkDefinition(
        'trojan://pw@trojan.example.com:443?security=tls&sni=trojan.example.com',
      ),
    );

    final config = server.protocolConfig;

    expect(config, isA<TrojanConfig>());
    expect((config as TrojanConfig).address, 'trojan.example.com');
    expect(config.password, 'pw');
  });

  test('Server with a FullConfigDefinition resolves protocolConfig directly', () {
    const config = ShadowsocksConfig(
      address: 'ss.example.com',
      port: 8388,
      method: 'aes-256-gcm',
      password: 'secret',
    );
    final server = Server(
      id: 's2',
      name: 'Full-config server',
      definition: const FullConfigDefinition(config),
    );

    expect(server.protocolConfig, same(config));
  });

  test('Subscription.isLocal reflects whether url is set', () {
    final remote = Subscription(
      id: 'sub1',
      name: 'Remote',
      url: Uri.parse('https://example.com/sub'),
      servers: const [],
    );
    final local = Subscription(id: 'sub2', name: 'Local', url: null, servers: const []);

    expect(remote.isLocal, isFalse);
    expect(local.isLocal, isTrue);
  });

  test('Subscription equality is value-based across nested servers', () {
    final serverA = Server(
      id: 's1',
      name: 'A',
      definition: const ShareLinkDefinition('ss://x@host:1#r'),
    );
    final subA = Subscription(id: 'sub', name: 'N', url: null, servers: [serverA]);
    final subB = Subscription(id: 'sub', name: 'N', url: null, servers: [serverA]);

    expect(subA, subB);
    expect(subA.hashCode, subB.hashCode);
  });
}
