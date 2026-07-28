/// The set of tunneling drivers available to route traffic from a SOCKS5-only
/// core (see `CoreType.needsExternalDriver`) into a system-wide TUN.
enum DriverType {
  /// No external driver — used by cores that establish their own TUN.
  none,
  hevSocks5,
  tun2socks,
}
