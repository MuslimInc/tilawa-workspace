import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';

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
      final String? payload = response.payload;
      if (payload != null) {
        try {
          return Map<String, dynamic>.from(jsonDecode(payload) as Map);
        } catch (_) {}
      }
      return const {};
    }

    final pendingFcm = AppRouter.pendingFcmMessage;
    if (pendingFcm != null) {
      AppRouter.pendingFcmMessage = null;
      return pendingFcm.data;
    }

    return null;
  }
}
