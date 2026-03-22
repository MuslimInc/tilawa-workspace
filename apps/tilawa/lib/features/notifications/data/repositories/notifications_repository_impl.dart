import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../domain/repositories/notifications_repository.dart';
import '../../presentation/services/fcm_notification_handler_service.dart';
import '../datasources/notifications_remote_data_source.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
    this._remoteDataSource,
    this._dispatcher,
    this._fcmHandlerService,
  );

  final NotificationsRemoteDataSource _remoteDataSource;
  final INotificationDispatcher _dispatcher;
  final FCMNotificationHandlerService _fcmHandlerService;
  final Logger _logger = Logger();

  @override
  Future<void> requestPermission() async {
    final NotificationSettings settings =
        await _remoteDataSource.requestPermission();
    _logger.d('Notification Status: ${settings.authorizationStatus}');
  }

  @override
  Future<String?> getToken() async {
    try {
      final String? token = await _remoteDataSource.getToken();
      return token;
    } catch (e) {
      _logger.e('Error getting FCM token', error: e);
      return null;
    }
  }

  @override
  Future<void> initializeListeners() async {
    // Register tap handler with the central dispatcher
    _dispatcher.registerPayloadHandler(
      serviceId: 'fcm_service',
      matcher: (payload) {
        if (payload == null) return false;
        try {
          final data = jsonDecode(payload);
          return data['type'] != null; // Basic heuristic for FCM deep-links
        } catch (_) {
          return false;
        }
      },
      handler: _fcmHandlerService.handleNotificationResponse,
    );

    // Handle Foreground Messages
    _remoteDataSource.onMessage.listen((RemoteMessage message) {
      _logger.d('Foreground Message: ${message.messageId}');
      _fcmHandlerService.showForegroundNotification(message);
    });

    // Handle Background/Terminated Taps
    _remoteDataSource.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.d('Background Message Tap: ${message.messageId}');
      _fcmHandlerService.handleNotificationResponse(
        NotificationResponse(
          id: message.hashCode,
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: jsonEncode(message.data),
        ),
      );
    });
  }
}
