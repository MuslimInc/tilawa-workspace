import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

@lazySingleton
class FCMNotificationHandlerService {
  final INotificationDispatcher _dispatcher;
  final Logger _logger;

  FCMNotificationHandlerService(this._dispatcher, this._logger);

  /// Handle notification response (tap)
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) {
      return;
    }

    try {
      final Map<String, dynamic> data = _normalizePayloadData(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
      final String location = resolveLocation(data);
      AppRouter.router.go(location);
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

    await _dispatcher.notificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  @visibleForTesting
  static String resolveLocation(Map<String, dynamic> payload) {
    final Map<String, dynamic> data = _normalizePayloadData(payload);
    final String type = data['type']?.toString() ?? 'home';
    final String? actionData = data['data']?.toString();

    switch (type) {
      case 'reciter':
        final String? reciterId = actionData?.trim().isNotEmpty == true
            ? actionData!.trim()
            : data['reciterId']?.toString();
        if (reciterId != null && reciterId.isNotEmpty) {
          return ReciterDetailsRoute(reciterId: reciterId).location;
        }
        return const HomeRoute().location;
      case 'athkar':
        final int? categoryId = int.tryParse(
          data['categoryId']?.toString() ?? '',
        );
        final String? categoryName = data['categoryName']?.toString();
        if (categoryId != null &&
            categoryName != null &&
            categoryName.trim().isNotEmpty) {
          return AthkarDetailsRoute(
            categoryId: categoryId,
            categoryName: categoryName,
          ).location;
        }
        return const AthkarCategoriesRoute().location;
      case 'quran':
        final int? surahNumber = int.tryParse(
          actionData?.trim().isNotEmpty == true
              ? actionData!.trim()
              : data['surahNumber']?.toString() ?? '',
        );
        if (surahNumber != null) {
          return QuranReaderRoute(surahNumber: surahNumber).location;
        }
        return const QuranLastReadRoute().location;
      case 'settings':
        return const SettingsRoute().location;
      case 'home':
      default:
        return const HomeRoute().location;
    }
  }

  @visibleForTesting
  static Map<String, dynamic> normalizePayloadForTest(
    Map<String, dynamic> payload,
  ) => _normalizePayloadData(payload);

  static Map<String, dynamic> _normalizePayloadData(
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(payload);

    normalized['type'] ??= normalized['actionType'];
    normalized['data'] ??= normalized['actionData'];

    if (normalized['type'] == null) {
      if (normalized['reciterId'] != null) {
        normalized['type'] = 'reciter';
      } else if (normalized['surahNumber'] != null) {
        normalized['type'] = 'quran';
      } else if (normalized['categoryId'] != null ||
          normalized['categoryName'] != null) {
        normalized['type'] = 'athkar';
      }
    }

    return normalized;
  }
}
