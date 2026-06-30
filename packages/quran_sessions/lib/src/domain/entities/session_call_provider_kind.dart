/// RTC / meeting infrastructure backing a session join.
///
/// Booking and lifecycle code depend on this enum — never on Agora or WebRTC
/// SDK types. The host app injects boundary implementations per kind.
enum SessionCallProviderKind {
  external,
  mock,
  agora,
  livekit,
}
