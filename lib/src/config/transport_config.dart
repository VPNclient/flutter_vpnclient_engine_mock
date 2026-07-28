import 'package:meta/meta.dart';

enum TransportType { tcp, ws, grpc, http2 }

@immutable
class TransportConfig {
  const TransportConfig({
    required this.type,
    this.path,
    this.host,
    this.serviceName,
  });

  final TransportType type;
  final String? path;
  final String? host;

  /// gRPC service name; only meaningful when [type] is [TransportType.grpc].
  final String? serviceName;

  TransportConfig copyWith({
    TransportType? type,
    String? path,
    String? host,
    String? serviceName,
  }) {
    return TransportConfig(
      type: type ?? this.type,
      path: path ?? this.path,
      host: host ?? this.host,
      serviceName: serviceName ?? this.serviceName,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'path': path,
        'host': host,
        'serviceName': serviceName,
      };

  factory TransportConfig.fromJson(Map<String, dynamic> json) {
    return TransportConfig(
      type: TransportType.values.byName(json['type'] as String),
      path: json['path'] as String?,
      host: json['host'] as String?,
      serviceName: json['serviceName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransportConfig &&
      other.type == type &&
      other.path == path &&
      other.host == host &&
      other.serviceName == serviceName;

  @override
  int get hashCode => Object.hash(type, path, host, serviceName);
}
