import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import '../../domain/entities/notification_action.dart';

@lazySingleton
class FCMNotificationHandlerService {
  final INotificationDispatcher _dispatcher;

  FCMNotificationHandlerService(this._dispatcher);

  /// Handle a notification response (tap) from the dispatcher
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final type = NotificationActionType.fromString(data['type'] as String?);
      final action = NotificationAction(type: type, data: data);

      _navigate(action);
    } catch (e) {
      // Log error
    }
  }

  /// Display a local notification when an FCM message arrives in foreground
  Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _dispatcher.notificationsPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'Push Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _navigate(NotificationAction action) {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    switch (action.type) {
      case NotificationActionType.reciter:
        final String? reciterId = action.data['reciterId'] as String?;
        if (reciterId != null) {
          ReciterDetailsRoute(reciterId: reciterId).go(context);
        }
        break;
      case NotificationActionType.athkar:
        final String? categoryIdStr = action.data['categoryId'] as String?;
        final String? categoryName = action.data['categoryName'] as String?;
        if (categoryIdStr != null && categoryName != null) {
          final int? categoryId = int.tryParse(categoryIdStr);
          if (categoryId != null) {
            AthkarDetailsRoute(categoryId: categoryId, categoryName: categoryName).go(context);
          }
        } else {
          const AthkarCategoriesRoute().go(context);
        }
        break;
      case NotificationActionType.quran:
        final String? surahStr = action.data['surahNumber'] as String?;
        if (surahStr != null) {
          final int? surahNumber = int.tryParse(surahStr);
          if (surahNumber != null) {
            QuranReaderRoute(surahNumber: surahNumber).go(context);
          }
        }
        break;
      case NotificationActionType.settings:
        const SettingsRoute().go(context);
        break;
      case NotificationActionType.home:
      case NotificationActionType.unknown:
        const HomeRoute().go(context);
        break;
    }
  }
}
