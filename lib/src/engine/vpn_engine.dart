import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';

import '../capabilities/engine_capabilities.dart';
import '../config/protocol_config.dart';
import '../cores/core_type.dart';
import '../drivers/driver_type.dart';
import '../mock/mock_behavior_config.dart';
import '../subscriptions/server.dart';
import 'connection_stats.dart';
import 'connection_state.dart';
import 'speed_test_result.dart';
import 'split_tunneling_config.dart';

/// Connection lifecycle, live stats, speed test, kill switch, split
/// tunneling, and core/driver selection — with a mocked native layer (no
/// FFI, no real tunnel; timing and throughput are simulated).
///
/// Plain constructible instance — no forced global singleton — so tests get
/// a fresh engine with no cross-test leakage.
class VpnEngine {
  VpnEngine({
    required this.capabilities,
    this.mockBehavior = const MockBehaviorConfig(),
  }) : _random = Random(mockBehavior.seed) {
    corePriority = List.of(availableCores);
    driverPriority =
        List.of(availableDrivers.where((driver) => driver != DriverType.none));
  }

  final EngineCapabilities capabilities;
  final MockBehaviorConfig mockBehavior;

  Random _random;
  final Set<CoreType> _disabledCores = {};
  final Set<DriverType> _disabledDrivers = {};

  // --- Core/driver selection & priority ---

  List<CoreType> get availableCores =>
      CoreType.values.where(capabilities.supportsCore).toList();

  /// Ordered list, mutable; first entry is preferred. Seeded from
  /// [availableCores] at construction.
  List<CoreType> corePriority = const [];

  void setCoreEnabled(CoreType core, bool enabled) {
    if (!capabilities.supportsCore(core)) {
      throw UnsupportedError('$core is not supported on ${capabilities.platform}');
    }
    if (enabled) {
      _disabledCores.remove(core);
    } else {
      _disabledCores.add(core);
    }
  }

  bool isCoreEnabled(CoreType core) => !_disabledCores.contains(core);

  List<DriverType> get availableDrivers =>
      DriverType.values.where(capabilities.supportsDriver).toList();

  /// Ordered list, mutable; first entry is preferred. Seeded from
  /// [availableDrivers] (excluding [DriverType.none]) at construction.
  List<DriverType> driverPriority = const [];

  void setDriverEnabled(DriverType driver, bool enabled) {
    if (!capabilities.supportsDriver(driver)) {
      throw UnsupportedError('$driver is not supported on ${capabilities.platform}');
    }
    if (enabled) {
      _disabledDrivers.remove(driver);
    } else {
      _disabledDrivers.add(driver);
    }
  }

  bool isDriverEnabled(DriverType driver) => !_disabledDrivers.contains(driver);

  // --- Connection lifecycle ---

  VpnConnectionState _state = const Disconnected();
  final _stateController = StreamController<VpnConnectionState>.broadcast();

  VpnConnectionState get state => _state;
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  void _setState(VpnConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> connect(
    Server server, {
    CoreType? coreOverride,
    DriverType? driverOverride,
  }) async {
    final core = _resolveCore(coreOverride);
    _resolveDriver(core, driverOverride);
    _validateProtocolCompatibility(server.protocolConfig, core);

    final failureReason = _pendingFailureReason;
    _pendingFailureReason = null;

    _setState(const Connecting());
    await Future<void>.delayed(mockBehavior.connectDelay);

    if (failureReason != null) {
      _setState(ConnectionFailed(failureReason));
      return;
    }

    _setState(Connected(DateTime.now()));
    _startStatsTimer();
  }

  Future<void> disconnect() async {
    if (_state is Disconnected || _state is Disconnecting) return;
    _setState(const Disconnecting());
    _stopStatsTimer();
    _setState(const Disconnected());
  }

  CoreType _resolveCore(CoreType? override) {
    if (override != null) {
      if (!capabilities.supportsCore(override)) {
        throw UnsupportedError(
          '$override is not supported on ${capabilities.platform}',
        );
      }
      if (!isCoreEnabled(override)) {
        throw ArgumentError('$override is disabled');
      }
      return override;
    }
    for (final core in corePriority) {
      if (capabilities.supportsCore(core) && isCoreEnabled(core)) return core;
    }
    throw ArgumentError('No enabled and supported core available');
  }

  DriverType _resolveDriver(CoreType core, DriverType? override) {
    if (!core.needsExternalDriver) return DriverType.none;
    if (override != null) {
      if (!capabilities.supportsDriver(override)) {
        throw UnsupportedError(
          '$override is not supported on ${capabilities.platform}',
        );
      }
      if (!isDriverEnabled(override)) {
        throw ArgumentError('$override is disabled');
      }
      return override;
    }
    for (final driver in driverPriority) {
      if (driver == DriverType.none) continue;
      if (capabilities.supportsDriver(driver) && isDriverEnabled(driver)) {
        return driver;
      }
    }
    throw ArgumentError('No enabled and supported driver available for $core');
  }

  void _validateProtocolCompatibility(ProtocolConfig config, CoreType core) {
    final isWireGuardConfig = config is WireGuardConfig;
    final isWireGuardCore = core == CoreType.wireguard;
    if (isWireGuardConfig != isWireGuardCore) {
      throw ArgumentError('${config.runtimeType} is not compatible with $core');
    }
  }

  // --- Stats ---

  ConnectionStats? _stats;
  final _statsController = StreamController<ConnectionStats>.broadcast();
  Timer? _statsTimer;
  int _bytesSentTotal = 0;
  int _bytesReceivedTotal = 0;

  ConnectionStats? get stats => _stats;
  Stream<ConnectionStats> get statsStream => _statsController.stream;

  void _startStatsTimer() {
    _bytesSentTotal = 0;
    _bytesReceivedTotal = 0;
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickStats());
  }

  void _tickStats() {
    final uploadRate = 20000 + _random.nextDouble() * 500000;
    final downloadRate = 50000 + _random.nextDouble() * 2000000;
    _bytesSentTotal += uploadRate.round();
    _bytesReceivedTotal += downloadRate.round();
    final stats = ConnectionStats(
      bytesSentTotal: _bytesSentTotal,
      bytesReceivedTotal: _bytesReceivedTotal,
      currentUploadBytesPerSecond: uploadRate,
      currentDownloadBytesPerSecond: downloadRate,
      latency: Duration(milliseconds: 20 + _random.nextInt(80)),
    );
    _stats = stats;
    _statsController.add(stats);
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _stats = null;
  }

  Future<SpeedTestResult> runSpeedTest() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return SpeedTestResult(
      downloadMbps: 20 + _random.nextDouble() * 480,
      uploadMbps: 5 + _random.nextDouble() * 95,
      latency: Duration(milliseconds: 15 + _random.nextInt(60)),
    );
  }

  // --- Kill switch / split tunneling ---

  bool _killSwitchEnabled = false;

  bool get killSwitchEnabled => _killSwitchEnabled;

  set killSwitchEnabled(bool value) {
    if (!capabilities.killSwitchSupported) {
      throw UnsupportedError('Kill switch is not supported on ${capabilities.platform}');
    }
    _killSwitchEnabled = value;
  }

  SplitTunnelingConfig _splitTunneling = const SplitTunnelingConfig();

  SplitTunnelingConfig get splitTunneling => _splitTunneling;

  set splitTunneling(SplitTunnelingConfig value) {
    if (!capabilities.splitTunnelingSupported) {
      throw UnsupportedError(
        'Split tunneling is not supported on ${capabilities.platform}',
      );
    }
    _splitTunneling = value;
  }

  // --- QA hooks backing MockEngineController (see lib/src/mock/) ---

  String? _pendingFailureReason;

  /// Makes exactly the next [connect] call fail with [reason] instead of
  /// succeeding. Not part of the target real-engine API — QA-only.
  @visibleForTesting
  void primeConnectFailure(String reason) {
    _pendingFailureReason = reason;
  }

  /// Overrides the next emitted [stats] value. QA-only.
  @visibleForTesting
  void forceStats(ConnectionStats stats) {
    _stats = stats;
    _statsController.add(stats);
  }

  /// Replaces the internal RNG so subsequent simulated values are
  /// reproducible from this point on. QA-only.
  @visibleForTesting
  void reseedRandom(int seed) {
    _random = Random(seed);
  }

  Future<void> dispose() async {
    _stopStatsTimer();
    await _stateController.close();
    await _statsController.close();
  }
}
