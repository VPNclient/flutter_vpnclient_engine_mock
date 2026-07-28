import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/capabilities/engine_capabilities.dart';
import 'package:vpnclient_engine/src/capabilities/platform_target.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/drivers/driver_type.dart';

void main() {
  test('default matrix: everything supported everywhere except h2', () {
    for (final platform in PlatformTarget.values) {
      final caps = EngineCapabilities(platform: platform);
      for (final core in CoreType.values) {
        final expected = core == CoreType.h2
            ? (platform == PlatformTarget.macos || platform == PlatformTarget.linux)
            : true;
        expect(
          caps.supportsCore(core),
          expected,
          reason: '$core on $platform',
        );
      }
      for (final driver in DriverType.values) {
        expect(caps.supportsDriver(driver), isTrue, reason: '$driver on $platform');
      }
      expect(caps.killSwitchSupported, isTrue);
      expect(caps.splitTunnelingSupported, isTrue);
    }
  });

  test('copyWithOverrides narrows without mutating the original', () {
    final original = const EngineCapabilities(platform: PlatformTarget.ios);
    final overridden = original.copyWithOverrides(
      coreOverrides: {CoreType.wireguard: false},
      killSwitchOverride: false,
    );

    expect(overridden.supportsCore(CoreType.wireguard), isFalse);
    expect(overridden.killSwitchSupported, isFalse);

    expect(original.supportsCore(CoreType.wireguard), isTrue);
    expect(original.killSwitchSupported, isTrue);
  });

  test('h2 stays unsupported on ios even after unrelated overrides', () {
    final caps = const EngineCapabilities(platform: PlatformTarget.ios)
        .copyWithOverrides(killSwitchOverride: false);
    expect(caps.supportsCore(CoreType.h2), isFalse);
  });
}
