/// The VPN connection's current lifecycle state.
///
/// Exhaustively matched with a sealed `switch`, not `is`-checked against an
/// open hierarchy or a flat enum with attached nullable fields.
///
/// Named `VpnConnectionState` rather than `ConnectionState` because Flutter
/// itself exports a widely-used `ConnectionState` enum (`StreamBuilder`/
/// `FutureBuilder`) — reusing that name would force every consumer to hide
/// one or the other on import.
sealed class VpnConnectionState {
  const VpnConnectionState();
}

class Disconnected extends VpnConnectionState {
  const Disconnected();
}

class Connecting extends VpnConnectionState {
  const Connecting();
}

class Connected extends VpnConnectionState {
  const Connected(this.since);

  final DateTime since;
}

class Disconnecting extends VpnConnectionState {
  const Disconnecting();
}

class ConnectionFailed extends VpnConnectionState {
  const ConnectionFailed(this.reason);

  final String reason;
}
