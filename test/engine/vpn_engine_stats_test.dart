import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/capabilities/engine_capabilities.dart';
import 'package:vpnclient_engine/src/capabilities/platform_target.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
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

void main() {
  test('same seed produces identical runSpeedTest() results across fresh instances', () async {
    final a = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(seed: 42),
    );
    final b = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(seed: 42),
    );

    final resultA = await a.runSpeedTest();
    final resultB = await b.runSpeedTest();

    expect(resultA.downloadMbps, resultB.downloadMbps);
    expect(resultA.uploadMbps, resultB.uploadMbps);
    expect(resultA.latency, resultB.latency);
  });

  test('stats stream emits computed current throughput, not just cumulative totals', () async {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
      mockBehavior: const MockBehaviorConfig(connectDelay: Duration.zero, seed: 1),
    );
    await engine.connect(_xrayServer());

    final stats = await engine.statsStream.first;
    expect(stats.currentUploadBytesPerSecond, greaterThan(0));
    expect(stats.currentDownloadBytesPerSecond, greaterThan(0));
    expect(stats.bytesSentTotal, greaterThan(0));
    expect(stats.bytesReceivedTotal, greaterThan(0));
    expect(engine.stats, isNotNull);

    await engine.disconnect();
    expect(engine.stats, isNull);
  });

  test('killSwitchEnabled = true throws UnsupportedError when unsupported', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux)
          .copyWithOverrides(killSwitchOverride: false),
    );
    expect(() => engine.killSwitchEnabled = true, throwsUnsupportedError);
  });

  test('splitTunneling setter throws UnsupportedError when unsupported', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux)
          .copyWithOverrides(splitTunnelingOverride: false),
    );
    expect(
      () => engine.splitTunneling = engine.splitTunneling.copyWith(enabled: true),
      throwsUnsupportedError,
    );
  });

  test('killSwitchEnabled / splitTunneling round-trip when supported', () {
    final engine = VpnEngine(
      capabilities: const EngineCapabilities(platform: PlatformTarget.linux),
    );
    engine.killSwitchEnabled = true;
    expect(engine.killSwitchEnabled, isTrue);

    engine.splitTunneling = engine.splitTunneling.copyWith(enabled: true, appIds: ['com.app']);
    expect(engine.splitTunneling.enabled, isTrue);
    expect(engine.splitTunneling.appIds, ['com.app']);
  });
}
