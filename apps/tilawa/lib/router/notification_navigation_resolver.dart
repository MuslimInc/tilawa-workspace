import 'dart:convert';

import 'package:tilawa/features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Resolves notification payload data into a go_router location and optional
/// route [extra] (e.g. [ReciterEntity] to skip detail loaders).
class NotificationNavigationResolver {
  NotificationNavigationResolver._();

  static String resolveLocation(Map<String, dynamic> data) {
    return FCMNotificationHandlerService.resolveLocation(data);
  }

  /// Returns route [extra] when the payload carries enough data to render
  /// without an async loader (e.g. embedded `reciter` JSON).
  static Object? resolveExtra(Map<String, dynamic> data, String location) {
    final String path = Uri.parse(location).path;
    if (path.startsWith('/reciter/')) {
      return _resolveReciterExtra(data);
    }
    if (path == const PrayerNotificationStatusRoute().location) {
      final Object? payload = data['payload'] ?? data['adhanPayload'];
      if (payload is String && payload.isNotEmpty) {
        return payload;
      }
    }
    return null;
  }

  static ReciterEntity? _resolveReciterExtra(Map<String, dynamic> data) {
    final Object? embedded = data['reciter'] ?? data['reciterEntity'];
    if (embedded is Map) {
      try {
        return ReciterEntity.fromJson(
          Map<String, dynamic>.from(embedded),
        );
      } catch (_) {
        return null;
      }
    }
    if (embedded is String && embedded.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(embedded);
        if (decoded is Map<String, dynamic>) {
          return ReciterEntity.fromJson(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? notificationDataFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      return null;
    }
  }
}
