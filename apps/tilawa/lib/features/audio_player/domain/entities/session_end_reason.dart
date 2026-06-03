/// Why a listening session ended in the UI layer.
///
/// All session-end paths in [AudioPlayerBloc] must converge on the same dismiss
/// semantics regardless of trigger.
enum SessionEndReason {
  /// User tapped stop in the app or [StopAudio] use case succeeded.
  inAppStop,

  /// Native session became idle (notification stop, handler [stop], etc.).
  externalIdle,

  /// [SyncActivePlayback] received an inactive snapshot (tests / future paths).
  syncInactiveSnapshot,
}
