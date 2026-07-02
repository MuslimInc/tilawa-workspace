import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa/core/config/android_notification_defaults.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

@lazySingleton
class FCMNotificationHandlerService {
  final INotificationDispatcher _dispatcher;
  final Logger _logger;
  final NavigationService _navigationService;

  FCMNotificationHandlerService(
    this._dispatcher,
    this._logger,
    this._navigationService,
  );

  /// Handle a tapped remote message using the same path for background and
  /// terminated launches.
  Future<void> handleRemoteMessageTap(RemoteMessage message) async {
    final Map<String, dynamic> payload = _normalizePayloadData(message.data);
    await handleNotificationResponse(
      NotificationResponse(
        id: message.hashCode,
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: jsonEncode(payload),
      ),
    );
  }

  /// Handle notification response (tap)
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) {
      return;
    }

    try {
      if (response.actionId == 'decline_call') {
        _logger.i('User declined incoming session call');
        return;
      }

      final Map<String, dynamic> data = _normalizePayloadData(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
      final NotificationDestination destination = const DeepLinkResolver()
          .resolveFromData(data);
      _navigationService.routeToDestination(destination);
    } catch (e) {
      _logger.e('Error parsing notification payload: $e');
    }
  }

  /// Show local notification for foreground messages
  Future<void> showForegroundNotification(RemoteMessage message) async {
    final Map<String, dynamic> payload = _normalizePayloadData(message.data);
    final String? title =
        message.notification?.title ?? payload['title']?.toString();
    final String? body =
        message.notification?.body ?? payload['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final bool isIncomingCall =
        payload['actionType'] == 'incoming_quran_session_call';

    AndroidNotificationDetails androidDetails;
    if (isIncomingCall) {
      androidDetails = const AndroidNotificationDetails(
        'quran_session_calls',
        'Incoming Calls',
        channelDescription: 'Incoming Quran Session calls',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        icon: AndroidNotificationDefaults.smallIcon,
        color: AndroidNotificationDefaults.accentColor,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('accept_call', 'Join'),
          AndroidNotificationAction('decline_call', 'Decline'),
        ],
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: AndroidNotificationDefaults.smallIcon,
        color: AndroidNotificationDefaults.accentColor,
      );
    }

    await _dispatcher.notificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  /// Canonical payload → location mapping. Delegates to the single
  /// [DeepLinkResolver] so route shapes live in exactly one place.
  static String resolveLocation(Map<String, dynamic> payload) =>
      DeepLinkResolver.resolveLocation(payload);

  @visibleForTesting
  static Map<String, dynamic> normalizePayloadForTest(
    Map<String, dynamic> payload,
  ) => DeepLinkResolver.normalizePayloadData(payload);

  static Map<String, dynamic> _normalizePayloadData(
    Map<String, dynamic> payload,
  ) => DeepLinkResolver.normalizePayloadData(payload);
}
