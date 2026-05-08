/// Read-only permission probe used by background scheduling policy.
abstract interface class PrayerNotificationPermissionStatus {
  Future<bool> areNotificationsAllowed();
}
