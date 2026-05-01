import 'package:injectable/injectable.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';

import '../../domain/services/prayer_notification_permission_status.dart';

@LazySingleton(as: PrayerNotificationPermissionStatus)
class PrayerNotificationPermissionStatusImpl
    implements PrayerNotificationPermissionStatus {
  const PrayerNotificationPermissionStatusImpl(this._permissions);

  final NotificationPermissionService _permissions;

  @override
  Future<bool> areNotificationsAllowed() {
    return _permissions.isPermissionGranted();
  }
}
