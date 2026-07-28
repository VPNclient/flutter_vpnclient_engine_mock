import 'package:meta/meta.dart';

/// A one-shot achievable-speed benchmark, distinct from the passive
/// [ConnectionStats] stream.
@immutable
class SpeedTestResult {
  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latency,
  });

  final double downloadMbps;
  final double uploadMbps;
  final Duration latency;

  @override
  bool operator ==(Object other) =>
      other is SpeedTestResult &&
      other.downloadMbps == downloadMbps &&
      other.uploadMbps == uploadMbps &&
      other.latency == latency;

  @override
  int get hashCode => Object.hash(downloadMbps, uploadMbps, latency);
}
