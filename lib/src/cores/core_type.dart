/// The set of VPN cores this engine can drive.
///
/// [needsExternalDriver] is an inherent property of the core, not a
/// separately maintained matrix that can drift from this enum: SingBox and
/// WireGuard establish their own TUN device, while LibXray, V2Ray, and h2
/// only expose a local SOCKS5 proxy and need an external tunneling driver.
enum CoreType {
  singbox(needsExternalDriver: false),
  wireguard(needsExternalDriver: false),
  libxray(needsExternalDriver: true),
  v2ray(needsExternalDriver: true),
  h2(needsExternalDriver: true);

  const CoreType({required this.needsExternalDriver});

  /// Whether this core requires a [DriverType] (other than [DriverType.none])
  /// to actually tunnel traffic, as opposed to establishing its own TUN.
  final bool needsExternalDriver;
}
