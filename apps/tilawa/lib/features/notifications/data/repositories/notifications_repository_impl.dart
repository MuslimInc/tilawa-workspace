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
    this._handler,
    this._logger,
  );

  final NotificationsRemoteDataSource _remoteDataSource;
  final INotificationDispatcher _dispatcher;
  final FCMNotificationHandlerService _handler;
  final Logger _logger;

  @override
  Future<void> requestPermission() async {
    final NotificationSettings settings = await _remoteDataSource
        .requestPermission();
    _logger.d('Notification permission: ${settings.authorizationStatus}');
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
    // 1. Listen for dynamic FCM events from RemoteDataSource
    _remoteDataSource.onMessage.listen((RemoteMessage message) {
      _handler.showForegroundNotification(message);
    });

    // 2. Listen for app opens from terminated state
    _remoteDataSource.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handler.handleNotificationResponse(
          NotificationResponse(
            id: message.hashCode,
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: jsonEncode(message.data),
          ),
        );
      }
    });

    // 3. Listen for app opens from background state
    _remoteDataSource.onMessageOpenedApp.listen((RemoteMessage message) {
      _handler.handleNotificationResponse(
        NotificationResponse(
          id: message.hashCode,
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: jsonEncode(message.data),
        ),
      );
    });

    // 4. Register for global notification actions via Dispatcher
    _dispatcher.registerPayloadHandler(
      serviceId: 'fcm_service',
      matcher: (payload) {
        if (payload == null) return false;
        try {
          final data = jsonDecode(payload);
          return data['type'] != null || data['actionType'] != null;
        } catch (_) {
          return false;
        }
      },
      handler: (response) => _handler.handleNotificationResponse(response),
    );
  }
}
