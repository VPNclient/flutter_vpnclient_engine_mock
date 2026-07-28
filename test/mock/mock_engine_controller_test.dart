import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/capabilities/engine_capabilities.dart';
import 'package:vpnclient_engine/src/capabilities/platform_target.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/engine/vpn_engine.dart';
import 'package:vpnclient_engine/src/mock/mock_behavior_config.dart';
import 'package:vpnclient_engine/src/mock/mock_engine_controller.dart';
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

void main() {
  test('simulateFailureOnNextConnect affects exactly the next connect(), then reverts', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(connectDelay: Duration.zero),
    );
    final controller = MockEngineController(engine);

    controller.simulateFailureOnNextConnect('simulated timeout');

    await engine.connect(_xrayServer());
    expect(engine.state, isA<ConnectionFailed>());
    expect((engine.state as ConnectionFailed).reason, 'simulated timeout');

    await engine.disconnect();
    await engine.connect(_xrayServer());
    expect(engine.state, isA<Connected>());
  });
}
