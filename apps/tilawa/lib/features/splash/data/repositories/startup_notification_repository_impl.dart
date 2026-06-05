import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/deep_link_resolver.dart';

import '../../domain/repositories/startup_notification_repository.dart';

@LazySingleton(as: StartupNotificationRepository)
class StartupNotificationRepositoryImpl
    implements StartupNotificationRepository {
  @override
  Map<String, dynamic>? consumePendingNotification() {
    final NotificationResponse? response =
        AppRouter.pendingLocalNotificationResponse;
    if (response != null) {
      AppRouter.pendingLocalNotificationResponse = null;
      AppRouter.lastProcessedNotificationId = response.id;
      // Shared resolver understands both JSON payloads and the plain-string
      // athkar payloads; empty map signals "launched from a notification but
      // no destination data" so the splash falls back to home.
      return DeepLinkResolver.notificationDataFromPayload(response.payload) ??
          const {};
    }

    final pendingFcm = AppRouter.pendingFcmMessage;
    if (pendingFcm != null) {
      AppRouter.pendingFcmMessage = null;
      return pendingFcm.data;
    }

    return null;
  }
}
