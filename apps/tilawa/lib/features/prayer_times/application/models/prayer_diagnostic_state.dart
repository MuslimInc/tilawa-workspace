class PrayerDiagnosticState {
  final bool isCalculated;
  final bool isPersisted;
  final bool isExactPermissionAvailable;
  final bool isExactScheduled;
  final bool isInexactFallbackScheduled;
  final bool isOSAlarmObserved;
  final bool isReceiverTriggered;
  final bool isForegroundServiceStarted;
  final bool isNotificationDisplayed;
  final bool isPlaybackStarted;
  final bool isPlaybackCompleted;
  final bool isPlaybackFailed;
  final bool isSuppressedOrUnknown;

  const PrayerDiagnosticState({
    required this.isCalculated,
    required this.isPersisted,
    required this.isExactPermissionAvailable,
    required this.isExactScheduled,
    required this.isInexactFallbackScheduled,
    required this.isOSAlarmObserved,
    required this.isReceiverTriggered,
    required this.isForegroundServiceStarted,
    required this.isNotificationDisplayed,
    required this.isPlaybackStarted,
    required this.isPlaybackCompleted,
    required this.isPlaybackFailed,
    required this.isSuppressedOrUnknown,
  });
}
