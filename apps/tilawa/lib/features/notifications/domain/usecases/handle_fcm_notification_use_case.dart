import '../entities/notification_action.dart';

class HandleFcmNotificationUseCase {
  HandleFcmNotificationUseCase();

  NotificationAction call(Map<String, dynamic> data) {
    final String? typeStr = data['type'] as String?;
    final type = NotificationActionType.fromString(typeStr);

    return NotificationAction(type: type, data: data);
  }
}
