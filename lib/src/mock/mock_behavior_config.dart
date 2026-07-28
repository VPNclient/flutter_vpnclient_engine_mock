import 'package:meta/meta.dart';

/// Tunes the mocked engine's simulated timing and randomness.
///
/// Passed to a [VpnEngine] constructor, not a global — so QA scenarios are
/// reproducible per-instance and tests get no cross-test leakage.
@immutable
class MockBehaviorConfig {
  const MockBehaviorConfig({
    this.seed,
    this.connectDelay = const Duration(milliseconds: 800),
  });

  /// Seeds the pseudo-random generator behind stats/speed-test simulation.
  /// Null means non-deterministic (`Random()` with no seed).
  final int? seed;

  final Duration connectDelay;

  @override
  bool operator ==(Object other) =>
      other is MockBehaviorConfig &&
      other.seed == seed &&
      other.connectDelay == connectDelay;

  @override
  int get hashCode => Object.hash(seed, connectDelay);
}
