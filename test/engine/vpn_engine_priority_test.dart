import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/capabilities/engine_capabilities.dart';
import 'package:vpnclient_engine/src/capabilities/platform_target.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/drivers/driver_type.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/engine/vpn_engine.dart';
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
  test('setCoreEnabled throws UnsupportedError for a platform-unsupported core, no state change', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.ios),
    );
    expect(engine.state, isA<Disconnected>());
    expect(
      () => engine.setCoreEnabled(CoreType.h2, true),
      throwsUnsupportedError,
    );
    expect(engine.state, isA<Disconnected>());
  });

  test('setDriverEnabled throws UnsupportedError for a platform-unsupported driver', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.ios)
          .copyWithOverrides(driverOverrides: {DriverType.tun2socks: false}),
    );
    expect(
      () => engine.setDriverEnabled(DriverType.tun2socks, true),
      throwsUnsupportedError,
    );
  });

  test('disabling the only compatible core makes connect() throw ArgumentError', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
    );
    for (final core in CoreType.values) {
      engine.setCoreEnabled(core, false);
    }

    expect(
      () => engine.connect(_xrayServer()),
      throwsArgumentError,
    );
  });

  test('isCoreEnabled defaults to true and reflects setCoreEnabled', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
    );
    expect(engine.isCoreEnabled(CoreType.singbox), isTrue);
    engine.setCoreEnabled(CoreType.singbox, false);
    expect(engine.isCoreEnabled(CoreType.singbox), isFalse);
    engine.setCoreEnabled(CoreType.singbox, true);
    expect(engine.isCoreEnabled(CoreType.singbox), isTrue);
  });
}
