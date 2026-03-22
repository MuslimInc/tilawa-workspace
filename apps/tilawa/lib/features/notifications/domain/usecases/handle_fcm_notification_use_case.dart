import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import '../entities/notification_action.dart';

@lazySingleton
class HandleFcmNotificationUseCase {
  HandleFcmNotificationUseCase();

  NotificationAction call(RemoteMessage message) {
    final data = message.data;
    final String? typeStr = data['type'] as String?;
    final type = NotificationActionType.fromString(typeStr);

    return NotificationAction(
      type: type,
      data: data,
    );
  }
}
