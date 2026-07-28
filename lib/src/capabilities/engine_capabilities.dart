import 'package:meta/meta.dart';

import '../cores/core_type.dart';
import '../drivers/driver_type.dart';
import 'platform_target.dart';

/// The per-(capability, platform) support matrix.
///
/// Default: everything is supported on every [PlatformTarget], **except**
/// [CoreType.h2] which reflects h2.core's actual documented constraint
/// (macOS + Linux desktop only, no Windows/iOS/Android) — the one entry that
/// encodes a real constraint rather than a seeded placeholder.
@immutable
class EngineCapabilities {
  const EngineCapabilities({required this.platform})
      : _coreOverrides = null,
        _driverOverrides = null,
        _killSwitchOverride = null,
        _splitTunnelingOverride = null;

  const EngineCapabilities._({
    required this.platform,
    Map<CoreType, bool>? coreOverrides,
    Map<DriverType, bool>? driverOverrides,
    bool? killSwitchOverride,
    bool? splitTunnelingOverride,
  })  : _coreOverrides = coreOverrides,
        _driverOverrides = driverOverrides,
        _killSwitchOverride = killSwitchOverride,
        _splitTunnelingOverride = splitTunnelingOverride;

  final PlatformTarget platform;
  final Map<CoreType, bool>? _coreOverrides;
  final Map<DriverType, bool>? _driverOverrides;
  final bool? _killSwitchOverride;
  final bool? _splitTunnelingOverride;

  bool supportsCore(CoreType core) {
    final override = _coreOverrides?[core];
    if (override != null) return override;
    if (core == CoreType.h2) {
      return platform == PlatformTarget.macos || platform == PlatformTarget.linux;
    }
    return true;
  }

  bool supportsDriver(DriverType driver) => _driverOverrides?[driver] ?? true;

  bool get killSwitchSupported => _killSwitchOverride ?? true;

  bool get splitTunnelingSupported => _splitTunnelingOverride ?? true;

  /// Escape hatch for tests/QA to override the matrix without touching the
  /// enum. Returns a new instance — [this] is never mutated.
  EngineCapabilities copyWithOverrides({
    Map<CoreType, bool>? coreOverrides,
    Map<DriverType, bool>? driverOverrides,
    bool? killSwitchOverride,
    bool? splitTunnelingOverride,
  }) {
    return EngineCapabilities._(
      platform: platform,
      coreOverrides: {...?_coreOverrides, ...?coreOverrides},
      driverOverrides: {...?_driverOverrides, ...?driverOverrides},
      killSwitchOverride: killSwitchOverride ?? _killSwitchOverride,
      splitTunnelingOverride: splitTunnelingOverride ?? _splitTunnelingOverride,
    );
  }
}
