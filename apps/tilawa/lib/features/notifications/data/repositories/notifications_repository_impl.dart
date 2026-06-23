import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:tilawa/core/services/prayer_notification_payload_classifier.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../domain/repositories/notifications_repository.dart';
import '../../presentation/services/fcm_notification_handler_service.dart';
import '../../../settings/domain/services/teacher_capability_refresh_notifier.dart';
import '../../../auth/domain/services/session_revoked_notifier.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../fcm_session_revoked_message.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
    this._remoteDataSource,
    this._dispatcher,
    this._handler,
    this._logger,
    this._teacherCapabilityRefreshNotifier,
    this._sessionRevokedNotifier,
  );

  final NotificationsRemoteDataSource _remoteDataSource;
  final INotificationDispatcher _dispatcher;
  final FCMNotificationHandlerService _handler;
  final Logger _logger;
  final TeacherCapabilityRefreshNotifier _teacherCapabilityRefreshNotifier;
  final SessionRevokedNotifier _sessionRevokedNotifier;
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
      if (isExpectedFcmUnavailableError(e)) {
        _logger.d('FCM token unavailable on this device', error: e);
      } else {
        _logger.e('Error getting FCM token', error: e);
      }
      return null;
    }
  }

  /// True when FCM cannot run because Google Play Services / Instance ID is
  /// missing (common on AOSP emulators and sideloaded GMS-free devices).
  @visibleForTesting
  static bool isExpectedFcmUnavailableError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('missing_instanceid_service') ||
        message.contains('service_not_available') ||
        message.contains('google play services not available') ||
        message.contains('google_play_services_not_available') ||
        message.contains('missing google play services') ||
        message.contains('api_not_available');
  }

  @override
  Future<void> initializeListeners() async {
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    // 1. Listen for dynamic FCM events from RemoteDataSource
    _remoteDataSource.onMessage.listen(_handleForegroundMessage);

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

  void _handleForegroundMessage(RemoteMessage message) {
    final String? type = _normalizedType(message.data);
    if (type == 'teacher_application_reviewed') {
      final String status = message.data['status']?.toString() ?? '';
      _teacherCapabilityRefreshNotifier.notifyApplicationReviewed(status);
    }
    if (isSessionRevokedFcmMessage(message.data)) {
      _sessionRevokedNotifier.notifySessionRevoked();
    }
    _handler.showForegroundNotification(message);
  }

  bool _isFcmPayload(Map<String, dynamic> data) {
    final String? type = _normalizedType(data);
    if (type == null) {
      return false;
    }

    // Keep local prayer/adhan payloads owned by PrayerAdhanNotificationService.
    final NotificationPayloadKind kind = classifyPrayerNotificationData(data);
    if (isPrayerPayloadOwnedByPrayerService(kind)) {
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
}
