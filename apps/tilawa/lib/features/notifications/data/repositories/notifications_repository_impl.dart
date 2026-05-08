import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
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
  bool _listenersInitialized = false;

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
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    // 1. Listen for dynamic FCM events from RemoteDataSource
    _remoteDataSource.onMessage.listen((RemoteMessage message) {
      _handler.showForegroundNotification(message);
    });

    // 2. Listen for app opens from background state
    _remoteDataSource.onMessageOpenedApp.listen((RemoteMessage message) {
      _handler.handleRemoteMessageTap(message);
    });

    // 4. Register for global notification actions via Dispatcher
    _dispatcher.registerPayloadHandler(
      serviceId: 'fcm_service',
      matcher: (payload) {
        if (payload == null) return false;
        try {
          final dynamic decoded = jsonDecode(payload);
          if (decoded is! Map) return false;
          final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
          return _isFcmPayload(data);
        } catch (_) {
          return false;
        }
      },
      handler: (response) => _handler.handleNotificationResponse(response),
    );
  }

  bool _isFcmPayload(Map<String, dynamic> data) {
    final String? type = _normalizedType(data);
    if (type == null) {
      return false;
    }

    // Keep local prayer/adhan payloads owned by PrayerAdhanNotificationService.
    if (type == 'prayer' && _isLocalPrayerPayload(data)) {
      return false;
    }

    return true;
  }

  String? _normalizedType(Map<String, dynamic> data) {
    final dynamic rawType = data['type'] ?? data['actionType'];
    final String? type = rawType?.toString().trim();
    if (type == null || type.isEmpty) {
      return null;
    }
    return type.toLowerCase();
  }

  bool _isLocalPrayerPayload(Map<String, dynamic> data) {
    const Set<String> localPrayerKeys = <String>{
      'scheduled_time_ms',
      'scheduled_ms',
      'notification_id',
      'adhan_enabled',
      'is_adhan_playing',
      'prayer',
      'prayer_key',
      'date',
    };

    for (final String key in localPrayerKeys) {
      if (data.containsKey(key)) {
        return true;
      }
    }
    return false;
  }
}
