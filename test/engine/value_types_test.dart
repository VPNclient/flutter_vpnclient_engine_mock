import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/engine/connection_stats.dart';
import 'package:vpnclient_engine/src/engine/speed_test_result.dart';
import 'package:vpnclient_engine/src/engine/split_tunneling_config.dart';
import 'package:vpnclient_engine/src/mock/mock_behavior_config.dart';

void main() {
  test('ConnectionStats equality is value-based', () {
    const a = ConnectionStats(
      bytesSentTotal: 100,
      bytesReceivedTotal: 200,
      currentUploadBytesPerSecond: 1.5,
      currentDownloadBytesPerSecond: 2.5,
      latency: Duration(milliseconds: 50),
    );
    const b = ConnectionStats(
      bytesSentTotal: 100,
      bytesReceivedTotal: 200,
      currentUploadBytesPerSecond: 1.5,
      currentDownloadBytesPerSecond: 2.5,
      latency: Duration(milliseconds: 50),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('SpeedTestResult equality is value-based', () {
    const a = SpeedTestResult(downloadMbps: 100, uploadMbps: 20, latency: Duration(milliseconds: 30));
    const b = SpeedTestResult(downloadMbps: 100, uploadMbps: 20, latency: Duration(milliseconds: 30));
    expect(a, b);
  });

  test('SplitTunnelingConfig.copyWith overrides only given fields', () {
    const base = SplitTunnelingConfig();
    final updated = base.copyWith(enabled: true, appIds: ['com.example.app']);
    expect(updated.enabled, isTrue);
    expect(updated.mode, SplitTunnelMode.exclude);
    expect(updated.appIds, ['com.example.app']);
    expect(base.enabled, isFalse, reason: 'copyWith must not mutate original');
  });

  test('MockBehaviorConfig default connectDelay is 800ms and seed is null', () {
    const config = MockBehaviorConfig();
    expect(config.connectDelay, const Duration(milliseconds: 800));
    expect(config.seed, isNull);
  });
}
