import '../engine/connection_stats.dart';
import '../engine/vpn_engine.dart';

/// QA-only surface for seeding/forcing simulated [VpnEngine] behavior.
///
/// Kept in its own file, separate from [VpnEngine]'s connection/stats/
/// capability API, so it's obvious this is a mock-testing concern rather
/// than part of the engine's everyday surface.
class MockEngineController {
  MockEngineController(this._engine);

  final VpnEngine _engine;

  /// Makes exactly the next `connect()` call fail with [reason] (emitting
  /// `ConnectionFailed(reason)` instead of `Connected`), then reverts to
  /// normal behavior for subsequent calls.
  void simulateFailureOnNextConnect(String reason) {
    _engine.primeConnectFailure(reason);
  }

  /// Overrides the next emitted stats value.
  void forceStats(ConnectionStats stats) {
    _engine.forceStats(stats);
  }

  /// Reseeds the engine's internal RNG so subsequent simulated stats/speed
  /// test values are reproducible from this point on.
  void setRandomSeed(int seed) {
    _engine.reseedRandom(seed);
  }
}
