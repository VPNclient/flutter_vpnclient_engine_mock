import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/capabilities/engine_capabilities.dart';
import 'package:vpnclient_engine/src/capabilities/platform_target.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/engine/vpn_engine.dart';
import 'package:vpnclient_engine/src/mock/mock_behavior_config.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

Server _xrayServer() => Server(
      id: 's1',
      name: 'Xray server',
      definition: const FullConfigDefinition(
        ShadowsocksConfig(
          address: 'ss.example.com',
          port: 8388,
          method: 'aes-256-gcm',
          password: 'secret',
        ),
      ),
    );

Server _wireGuardServer() => Server(
      id: 's2',
      name: 'WireGuard server',
      definition: const FullConfigDefinition(
        WireGuardConfig(
          address: 'wg.example.com',
          port: 51820,
          publicKey: 'pub',
          privateKey: 'priv',
          allowedIps: ['0.0.0.0/0'],
        ),
      ),
    );

void main() {
  test('connect() -> disconnect() emits the full state sequence', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(connectDelay: Duration.zero),
    );
    final states = <VpnConnectionState>[];
    engine.stateStream.listen(states.add);

    await engine.connect(_xrayServer());
    expect(engine.state, isA<Connected>());

    await engine.disconnect();
    expect(engine.state, isA<Disconnected>());

    await Future<void>.delayed(Duration.zero);
    expect(states.map((s) => s.runtimeType).toList(), [
      Connecting,
      Connected,
      Disconnecting,
      Disconnected,
    ]);
  });

  test('connecting with an unsupported core throws before any state transition', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.ios),
    );
    final states = <VpnConnectionState>[];
    engine.stateStream.listen(states.add);

    await expectLater(
      () => engine.connect(_xrayServer(), coreOverride: CoreType.h2),
      throwsUnsupportedError,
    );
    expect(states, isEmpty);
    expect(engine.state, isA<Disconnected>());
  });

  test('WireGuardConfig only validates against CoreType.wireguard', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(connectDelay: Duration.zero),
    );

    expect(
      () => engine.connect(_wireGuardServer(), coreOverride: CoreType.singbox),
      throwsArgumentError,
    );

    await engine.connect(_wireGuardServer(), coreOverride: CoreType.wireguard);
    expect(engine.state, isA<Connected>());
  });
}
