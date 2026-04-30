/// Abstraction over the adhan audio playback mechanism.
///
/// Phase 1 ships a no-op implementation — the system notification sound is used
/// instead. Phase 2 will provide an implementation backed by the `alarm`
/// package that plays a bundled adhan asset at the scheduled time.
///
/// Implementations are isolated behind this interface so the underlying audio
/// library can be swapped without touching domain, BLoC, or UI code.
abstract interface class IAdhanAlarmPlayer {
  /// Whether this implementation can play adhan audio on the current device
  /// and platform. The Phase 1 no-op returns `false`.
  bool get isSupported;

  /// Schedule adhan audio playback for [scheduledTime]. The [id] is the same
  /// notification ID used for the corresponding visual notification so the
  /// audio and notification can be cancelled together.
  Future<void> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
  });

  /// Cancel a previously scheduled adhan by [id].
  Future<void> cancelAdhan(int id);

  /// Cancel every adhan scheduled by this player.
  Future<void> cancelAllAdhans();
}
