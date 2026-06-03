/// Abstraction over the adhan audio playback mechanism.
///
/// The Android implementation ([AndroidAdhanAlarmPlayer]) schedules a native
/// AlarmManager.setAlarmClock entry that fires a foreground service playing a
/// bundled adhan asset, so playback survives app termination and reboot.
///
/// Implementations are isolated behind this interface so the underlying audio
/// library can be swapped without touching domain, BLoC, or UI code.
abstract interface class IAdhanAlarmPlayer {
  /// Whether this implementation can play adhan audio on the current device
  /// and platform. Returns `false` on platforms where the native plumbing is
  /// absent (e.g. iOS, where this app does not currently ship).
  bool get isSupported;

  /// Stream of notification tap payloads.
  /// Fired when a native prayer notification is tapped.
  Stream<String> get onNotificationTapped;

  /// Pull any buffered native notification tap that could not be delivered
  /// live (for example while Flutter was temporarily detached) and emit it
  /// into [onNotificationTapped].
  Future<void> flushPendingNotificationTap();

  /// Consumes a buffered native tap from cold start without emitting
  /// [onNotificationTapped]. Returns the JSON payload, or null if none.
  Future<String?> pullPendingNotificationTapPayload();

  /// Schedule adhan audio playback for [scheduledTime]. The [id] is the same
  /// notification ID used for the corresponding visual notification so the
  /// audio and notification can be cancelled together.
  ///
  /// Returns `true` if the alarm was successfully scheduled. On Android, this
  /// may return `false` if exact-alarm permission is missing.
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
  });

  /// Starts adhan playback immediately via the native foreground service,
  /// without [AlarmManager]. Used when [scheduleAdhan] fails (e.g. exact alarm
  /// denied). Returns `false` when unsupported or start fails.
  Future<bool> playAdhanNow({
    required int id,
    required String prayerName,
    required String prayerKey,
    String? sound,
  });

  /// Cancel a previously scheduled adhan by [id].
  Future<void> cancelAdhan(int id, {String? prayerName});

  /// Cancel every adhan scheduled by this player.
  Future<void> cancelAllAdhans();

  /// Persist the next-window alarm list so the platform's boot receiver can
  /// re-install entries after device reboot without bringing up a Dart
  /// isolate. Implementations may no-op when not needed.
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms);

  /// Atomically read-and-clear the "the boot receiver fired since the app was
  /// last open" flag. Returning `true` signals the schedule pass should run
  /// even if the dedup fingerprint matches.
  Future<bool> consumeNeedsRescheduleAfterBoot();

  /// Mark the schedule as needing a full Dart-side rebuild.
  ///
  /// Used when a platform event invalidated alarms, but the current recovery
  /// attempt cannot safely rebuild the schedule yet.
  Future<void> markNeedsReschedule();

  /// Returns `true` if the app is currently exempt from battery optimisations,
  /// meaning it can reliably fire exact alarms even in Doze mode.
  Future<bool> isIgnoringBatteryOptimizations();

  /// Requests the system to exempt the app from battery optimisations.
  Future<void> requestIgnoreBatteryOptimizations();

  /// Returns the device manufacturer string (e.g., "Xiaomi", "Samsung").
  Future<String?> manufacturer();

  /// Stops the currently playing adhan audio if it is active.
  Future<void> stopCurrentAdhan();

  /// Returns `true` if the adhan audio is currently playing.
  Future<bool> isAdhanPlaying();

  /// Returns a JSON-encoded payload describing the currently-playing adhan
  /// (prayer name, scheduled time, sound, notification id), or `null` if no
  /// adhan is currently playing. Used to route the user to
  /// `PrayerNotificationStatusScreen` on resume when the foreground
  /// notification has been swiped away.
  Future<String?> getActiveAdhanPayload();
}

/// Tuple persisted for the boot receiver's re-arm path.
class PendingAdhanAlarm {
  const PendingAdhanAlarm({
    required this.id,
    required this.prayerName,
    required this.prayerKey,
    required this.triggerAt,
    this.sound,
  });

  final int id;
  final String prayerName;
  final String prayerKey;
  final DateTime triggerAt;
  final String? sound;
}
