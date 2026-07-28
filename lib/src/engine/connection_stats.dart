import 'package:meta/meta.dart';

/// A snapshot of connection statistics.
///
/// Carries **computed current throughput** alongside cumulative totals — the
/// engine computes this from its own polling, so the app never has to diff
/// two snapshots itself.
@immutable
class ConnectionStats {
  const ConnectionStats({
    required this.bytesSentTotal,
    required this.bytesReceivedTotal,
    required this.currentUploadBytesPerSecond,
    required this.currentDownloadBytesPerSecond,
    required this.latency,
  });

  final int bytesSentTotal;
  final int bytesReceivedTotal;
  final double currentUploadBytesPerSecond;
  final double currentDownloadBytesPerSecond;
  final Duration latency;

  @override
  bool operator ==(Object other) =>
      other is ConnectionStats &&
      other.bytesSentTotal == bytesSentTotal &&
      other.bytesReceivedTotal == bytesReceivedTotal &&
      other.currentUploadBytesPerSecond == currentUploadBytesPerSecond &&
      other.currentDownloadBytesPerSecond == currentDownloadBytesPerSecond &&
      other.latency == latency;

  @override
  int get hashCode => Object.hash(
        bytesSentTotal,
        bytesReceivedTotal,
        currentUploadBytesPerSecond,
        currentDownloadBytesPerSecond,
        latency,
      );
}
