import 'package:tilawa/core/services/notification_permission_service.dart';

import '../../domain/services/prayer_notification_permission_status.dart';

class PrayerNotificationPermissionStatusImpl
    implements PrayerNotificationPermissionStatus {
  const PrayerNotificationPermissionStatusImpl(this._permissions);

  final NotificationPermissionService _permissions;

  @override
  Future<bool> areNotificationsAllowed() {
    return _permissions.isPermissionGranted();
  }
}
