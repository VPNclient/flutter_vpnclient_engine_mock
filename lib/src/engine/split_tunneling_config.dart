import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

enum SplitTunnelMode { include, exclude }

@immutable
class SplitTunnelingConfig {
  const SplitTunnelingConfig({
    this.enabled = false,
    this.mode = SplitTunnelMode.exclude,
    this.appIds = const [],
  });

  final bool enabled;
  final SplitTunnelMode mode;

  /// Per-app identifiers (Android package name / iOS bundle id) the [mode]
  /// applies to.
  final List<String> appIds;

  static const _listEquality = ListEquality<String>();

  SplitTunnelingConfig copyWith({
    bool? enabled,
    SplitTunnelMode? mode,
    List<String>? appIds,
  }) {
    return SplitTunnelingConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      appIds: appIds ?? this.appIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SplitTunnelingConfig &&
      other.enabled == enabled &&
      other.mode == mode &&
      _listEquality.equals(other.appIds, appIds);

  @override
  int get hashCode => Object.hash(enabled, mode, _listEquality.hash(appIds));
}
