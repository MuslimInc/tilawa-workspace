import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../main.dart';
import '../config/notification_config.dart';

/// Handler registration data
class _HandlerRegistration {
  _HandlerRegistration({
    required this.serviceId,
    required this.notificationIds,
    required this.handler,
  });

  final String serviceId;
  final Set<int> notificationIds;
  final NotificationHandler handler;
}

/// Payload handler registration data
class _PayloadHandlerRegistration {
  _PayloadHandlerRegistration({
    required this.serviceId,
    required this.matcher,
    required this.handler,
  });

  final String serviceId;
  final bool Function(String? payload) matcher;
  final NotificationHandler handler;
}

/// Central notification dispatcher that routes notifications to appropriate services
///
/// This decouples notification services from each other by providing a central
/// routing mechanism based on notification IDs and payload patterns.
@LazySingleton(as: INotificationDispatcher)
class NotificationDispatcher implements INotificationDispatcher {
  NotificationDispatcher();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final List<_HandlerRegistration> _handlers = [];
  final List<_PayloadHandlerRegistration> _payloadHandlers = [];

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications) {
      logger.d('[NotificationDispatcher] Notifications disabled in config');
      return;
    }

    if (_initialized) {
      logger.d('[NotificationDispatcher] Already initialized');
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        'ic_launcher_monochrome',
      );
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Create High Importance Channel for Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        );

        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);

        logger.d('[NotificationDispatcher] High importance channel created');
      }

      _initialized = true;
      logger.d('[NotificationDispatcher] Initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        '[NotificationDispatcher] Initialization failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void registerHandler({
    required String serviceId,
    required Set<int> notificationIds,
    required NotificationHandler handler,
  }) {
    // Remove existing registration for this service
    _handlers.removeWhere((h) => h.serviceId == serviceId);

    _handlers.add(
      _HandlerRegistration(
        serviceId: serviceId,
        notificationIds: notificationIds,
        handler: handler,
      ),
    );

    logger.d(
      '[NotificationDispatcher] Registered handler for $serviceId with IDs: $notificationIds',
    );
  }

  @override
  void registerPayloadHandler({
    required String serviceId,
    required bool Function(String? payload) matcher,
    required NotificationHandler handler,
  }) {
    // Remove existing registration for this service
    _payloadHandlers.removeWhere((h) => h.serviceId == serviceId);

    _payloadHandlers.add(
      _PayloadHandlerRegistration(
        serviceId: serviceId,
        matcher: matcher,
        handler: handler,
      ),
    );

    logger.d(
      '[NotificationDispatcher] Registered payload handler for $serviceId',
    );
  }

  @override
  void unregisterHandler(String serviceId) {
    _handlers.removeWhere((h) => h.serviceId == serviceId);
    _payloadHandlers.removeWhere((h) => h.serviceId == serviceId);
    logger.d('[NotificationDispatcher] Unregistered handler for $serviceId');
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() {
    return _notifications.getNotificationAppLaunchDetails();
  }

  @override
  Future<bool> processLaunchNotification() async {
    if (!_initialized) {
      logger.w(
        '[NotificationDispatcher] Cannot process launch notification - not initialized',
      );
      return false;
    }

    try {
      final NotificationAppLaunchDetails? details = await _notifications
          .getNotificationAppLaunchDetails();

      logger.d(
        '[NotificationDispatcher] Launch details: didLaunch=${details?.didNotificationLaunchApp}, response=${details?.notificationResponse?.id}',
      );

      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        final NotificationResponse response = details.notificationResponse!;
        logger.d(
          '[NotificationDispatcher] Processing launch notification: id=${response.id}, payload=${response.payload}',
        );
        await _routeNotification(response);
        return true;
      }

      logger.d('[NotificationDispatcher] No launch notification to process');
      return false;
    } catch (e, stackTrace) {
      logger.e(
        '[NotificationDispatcher] Error processing launch notification: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Internal handler that routes notifications to the appropriate service
  void _handleNotificationResponse(NotificationResponse response) {
    logger.d(
      '[NotificationDispatcher] _handleNotificationResponse called: id=${response.id}, payload=${response.payload}',
    );
    // Fire and forget - the async operation will complete in background
    _routeNotification(response);
  }

  /// Route notification to the appropriate handler
  Future<void> _routeNotification(NotificationResponse response) async {
    final int? notificationId = response.id;
    final String? payload = response.payload;

    logger.d(
      '[NotificationDispatcher] Routing notification: id=$notificationId, payload=$payload',
    );

    // First, try to match by notification ID
    for (final _HandlerRegistration registration in _handlers) {
      if (notificationId != null &&
          registration.notificationIds.contains(notificationId)) {
        logger.d(
          '[NotificationDispatcher] Matched handler: ${registration.serviceId}',
        );
        await registration.handler(response);
        return;
      }
    }

    // If no ID match, try payload handlers
    for (final _PayloadHandlerRegistration registration in _payloadHandlers) {
      if (registration.matcher(payload)) {
        logger.d(
          '[NotificationDispatcher] Matched payload handler: ${registration.serviceId}',
        );
        await registration.handler(response);
        return;
      }
    }

    logger.w(
      '[NotificationDispatcher] No handler found for notification: id=$notificationId',
    );
  }

  /// Check if running on Android (for platform-specific logic)
  @visibleForTesting
  bool get isAndroid => Platform.isAndroid;

  /// Get the notifications plugin (for services that need to schedule notifications)
  @override
  FlutterLocalNotificationsPlugin get notificationsPlugin => _notifications;
}
