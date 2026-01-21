import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui/theme/app_colors.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../main.dart';
import '../../router/app_router.dart';
import '../../router/app_router_config.dart';
import '../config/notification_config.dart';

/// Service for scheduling daily athkar (remembrance) notifications
///
/// Schedules two daily notifications:
/// - 7:00 AM: Morning athkar (أذكار الصباح)
/// - 5:00 PM: Evening athkar (أذكار المساء)
@LazySingleton(as: IAthkarNotificationService)
class AthkarNotificationService implements IAthkarNotificationService {
  AthkarNotificationService(this._prefs, this._dispatcher);

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  static const String _lastHandledPayloadKey =
      'last_handled_notification_payload';
  static const String _lastHandledTimestampKey =
      'last_handled_notification_timestamp';

  /// Maximum time (in seconds) for a notification to be considered valid for launch handling.
  /// This prevents old sticky intents from triggering navigation on app restart.
  static const int _notificationValidityDurationSeconds = 60;

  /// Channel ID for athkar notifications
  static const String _athkarChannelId = 'com.tilawa.app.athkar';
  static const String _athkarChannelName = 'Athkar Reminders';
  static const String _athkarChannelDescription =
      'Daily reminders for morning and evening athkar';

  /// Notification IDs
  static const int _morningAthkarNotificationId = 1001;
  static const int _eveningAthkarNotificationId = 1002;

  /// Get notification IDs for external use (e.g., dispatcher registration)
  static Set<int> get notificationIds => {
    _morningAthkarNotificationId,
    _eveningAthkarNotificationId,
  };

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  bool _initialized = false;

  /// Initialize the notification service
  @override
  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications) {
      logger.d('[AthkarNotificationService] Notifications disabled in config');
      return;
    }

    if (_initialized) {
      logger.d('[AthkarNotificationService] Already initialized');
      return;
    }

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Set local timezone (try to use device timezone, fallback to UTC)
      try {
        final String? timeZoneName = await _getLocalTimeZone();
        if (timeZoneName != null) {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          logger.d(
            '[AthkarNotificationService] Timezone set to: $timeZoneName',
          );
        } else {
          tz.setLocalLocation(tz.UTC);
          logger.d('[AthkarNotificationService] Using UTC timezone');
        }
      } catch (e) {
        logger.w(
          '[AthkarNotificationService] Error setting timezone: $e, using UTC',
        );
        tz.setLocalLocation(tz.UTC);
      }

      // Initialize the dispatcher (which initializes the shared notification plugin)
      await _dispatcher.initialize();

      // Register our handler with the dispatcher
      _dispatcher.registerHandler(
        serviceId: 'athkar',
        notificationIds: notificationIds,
        handler: handleNotificationResponse,
      );

      // Create notification channel for Android
      if (isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _athkarChannelId,
            _athkarChannelName,
            description: _athkarChannelDescription,
            importance: Importance.high,
          ),
        );
      }

      _initialized = true;
      logger.d('[AthkarNotificationService] Initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        '[AthkarNotificationService] Initialization failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if the app was launched from an athkar notification
  /// Returns the notification response if so, null otherwise.
  ///
  /// This method uses multiple validation strategies:
  /// 1. Payload de-duplication to prevent handling the same notification twice
  /// 2. Timestamp validation to prevent old sticky intents from triggering navigation
  @override
  Future<NotificationResponse?> checkLaunchNotification() async {
    if (!_initialized) {
      await initialize();
    }

    final NotificationAppLaunchDetails? details = await _dispatcher
        .getNotificationAppLaunchDetails();

    if (details != null &&
        details.didNotificationLaunchApp &&
        details.notificationResponse != null) {
      final int? id = details.notificationResponse?.id;
      final String? payload = details.notificationResponse?.payload;

      // De-duplication check
      // We REQUIRE a payload to handle de-duplication correctly.
      // If payload is empty (legacy notification), we ignore it to prevent
      // sticky intent loops on hot restart.
      if (payload != null && payload.isNotEmpty) {
        final String? lastHandled = await _prefs.getString(
          _lastHandledPayloadKey,
        );

        if (lastHandled == payload) {
          logger.d(
            '[AthkarNotificationService] Ignoring already handled payload: $payload',
          );
          return null;
        }

        // Extract timestamp from payload and validate it's recent
        final int? payloadTimestamp = _extractTimestampFromPayload(payload);
        if (payloadTimestamp != null) {
          final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
          final int ageInSeconds =
              (currentTimestamp - payloadTimestamp) ~/ 1000;

          if (ageInSeconds > _notificationValidityDurationSeconds) {
            logger.d(
              '[AthkarNotificationService] Ignoring stale notification (age: ${ageInSeconds}s): $payload',
            );
            // Mark as handled to prevent future checks
            await _prefs.setString(_lastHandledPayloadKey, payload);
            return null;
          }
        }

        // Mark as handled with timestamp
        await _prefs.setString(_lastHandledPayloadKey, payload);
        await _prefs.setInt(
          _lastHandledTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        if (id == _morningAthkarNotificationId ||
            id == _eveningAthkarNotificationId) {
          logger.d(
            '[AthkarNotificationService] Valid notification tap detected: $payload',
          );
          return details.notificationResponse;
        }
      } else {
        logger.d(
          '[AthkarNotificationService] Ignoring empty payload to prevent sticky intent loop',
        );
        return null;
      }
    }

    return null;
  }

  /// Extract the timestamp from a notification payload
  /// Payload format: "morning_athkar_1234567890" or "evening_athkar_1234567890"
  int? _extractTimestampFromPayload(String payload) {
    try {
      final List<String> parts = payload.split('_');
      if (parts.length >= 3) {
        return int.tryParse(parts.last);
      }
    } catch (e) {
      logger.w(
        '[AthkarNotificationService] Failed to extract timestamp from payload: $payload',
      );
    }
    return null;
  }

  /// Clear the stored launch notification data
  /// Call this after successfully handling a notification navigation
  @override
  Future<void> clearLaunchNotificationData() async {
    try {
      await _prefs.remove(_lastHandledPayloadKey);
      await _prefs.remove(_lastHandledTimestampKey);
      logger.d('[AthkarNotificationService] Cleared launch notification data');
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error clearing launch notification data: $e',
      );
    }
  }

  /// Get the local timezone name for the device
  Future<String?> _getLocalTimeZone() async {
    try {
      // For Android and iOS, we can try to get the system timezone
      // This is a simple approach - in production you might want to use
      // a package like flutter_native_timezone for more accuracy

      // Map common offsets to timezone names
      final String offset = getTimeZoneOffsetString();

      if (offset.contains('2:00:00')) {
        return 'Africa/Cairo'; // EET (Egypt, common for Arabic users)
      } else if (offset.contains('3:00:00')) {
        return 'Asia/Riyadh'; // AST (Saudi Arabia)
      } else if (offset.contains('4:00:00')) {
        return 'Asia/Dubai'; // GST (UAE)
      }

      return null; // Fallback to UTC
    } catch (e) {
      logger.w('[AthkarNotificationService] Error detecting timezone: $e');
      return null;
    }
  }

  @visibleForTesting
  String getTimeZoneOffsetString() {
    final now = DateTime.now();
    return now.timeZoneOffset.toString();
  }

  /// Schedule athkar notifications (both morning and evening)
  @override
  Future<void> scheduleAthkarNotifications() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      await _scheduleMorningAthkar();
      await _scheduleEveningAthkar();
      logger.d(
        '[AthkarNotificationService] Scheduled all athkar notifications',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling notifications: $e',
      );
    }
  }

  /// Schedule morning athkar notification at 7:00 AM daily
  Future<void> _scheduleMorningAthkar() async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(7, 0);

      const androidDetails = AndroidNotificationDetails(
        _athkarChannelId,
        _athkarChannelName,
        channelDescription: _athkarChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher_monochrome',
        color: AppColors.notificationAccent,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        _morningAthkarNotificationId,
        'أذكار الصباح',
        'حان وقت أذكار الصباح 🌅',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning_athkar_${scheduledDate.millisecondsSinceEpoch}',
      );

      logger.d(
        '[AthkarNotificationService] Morning athkar scheduled for: $scheduledDate',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling morning athkar: $e',
      );
    }
  }

  /// Schedule evening athkar notification at 5:00 PM daily
  Future<void> _scheduleEveningAthkar() async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(17, 0);

      const androidDetails = AndroidNotificationDetails(
        _athkarChannelId,
        _athkarChannelName,
        channelDescription: _athkarChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher_monochrome',
        color: AppColors.notificationAccent,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        _eveningAthkarNotificationId,
        'أذكار المساء',
        'حان وقت أذكار المساء 🌙',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'evening_athkar_${scheduledDate.millisecondsSinceEpoch}',
      );

      logger.d(
        '[AthkarNotificationService] Evening athkar scheduled for: $scheduledDate',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling evening athkar: $e',
      );
    }
  }

  /// Calculate the next instance of a specific time (hour:minute)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Schedule a test notification (for testing purposes)
  /// Schedules a notification [minutesFromNow] minutes in the future
  @override
  Future<void> scheduleTestNotification({int minutesFromNow = 1}) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(minutes: minutesFromNow));

      const androidDetails = AndroidNotificationDetails(
        _athkarChannelId,
        _athkarChannelName,
        channelDescription: _athkarChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: AppColors.notificationAccent,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        9999, // Test notification ID
        'Test Athkar Notification',
        'This is a test notification scheduled for $scheduledDate',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      logger.d(
        '[AthkarNotificationService] Test notification scheduled for: $scheduledDate',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling test notification: $e',
      );
    }
  }

  /// Schedule a debug athkar notification with custom delay
  /// [isMorning] determines if it should act as morning or evening athkar
  /// This is useful for verifying routing logic as it uses the real notification IDs
  @override
  Future<void> scheduleDebugAthkarNotification({
    required bool isMorning,
    Duration delay = const Duration(seconds: 3),
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(delay);
      final int id = isMorning
          ? _morningAthkarNotificationId
          : _eveningAthkarNotificationId;
      final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
      final body = isMorning
          ? 'حان وقت أذكار الصباح 🌅'
          : 'حان وقت أذكار المساء 🌙';

      const androidDetails = AndroidNotificationDetails(
        _athkarChannelId,
        _athkarChannelName,
        channelDescription: _athkarChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher_monochrome',
        color: AppColors.notificationAccent,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final athkarPayload = isMorning
          ? 'morning_athkar_${scheduledDate.millisecondsSinceEpoch}'
          : 'evening_athkar_${scheduledDate.millisecondsSinceEpoch}';

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: athkarPayload,
      );

      logger.d(
        '[AthkarNotificationService] Debug athkar ($title) scheduled for: $scheduledDate',
      );
    } catch (e) {
      logger.e('[AthkarNotificationService] Error scheduling debug athkar: $e');
    }
  }

  /// Cancel all athkar notifications
  @override
  Future<void> cancelAllAthkarNotifications() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }

    try {
      await _notifications.cancel(_morningAthkarNotificationId);
      await _notifications.cancel(_eveningAthkarNotificationId);
      logger.d(
        '[AthkarNotificationService] Cancelled all athkar notifications',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error cancelling notifications: $e',
      );
    }
  }

  /// Handle notification tap (foreground/background)
  /// This also marks the payload as handled to prevent duplicate navigation on hot restart
  @override
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    logger.d('[AthkarNotificationService] Notification tapped: ${response.id}');

    final String? payload = response.payload;

    // Check if this payload was already handled (de-duplication)
    if (payload != null && payload.isNotEmpty) {
      final String? lastHandled = await _prefs.getString(
        _lastHandledPayloadKey,
      );
      if (lastHandled == payload) {
        logger.d(
          '[AthkarNotificationService] Ignoring already handled notification: $payload',
        );
        return;
      }

      // Mark as handled to prevent duplicate navigation
      await _prefs.setString(_lastHandledPayloadKey, payload);
      await _prefs.setInt(
        _lastHandledTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      logger.d(
        '[AthkarNotificationService] Marked payload as handled: $payload',
      );
    }

    if (response.id == _morningAthkarNotificationId) {
      logger.d(
        '[AthkarNotificationService] Morning athkar notification tapped - navigating',
      );
      const route = AthkarDetailsRoute(
        categoryId: 1,
        categoryName: 'أذكار الصباح',
      );
      // Use go to ensure clean navigation from any state
      _navigateToRoute(route.location);
    } else if (response.id == _eveningAthkarNotificationId) {
      logger.d(
        '[AthkarNotificationService] Evening athkar notification tapped - navigating',
      );
      const route = AthkarDetailsRoute(
        categoryId: 2,
        categoryName: 'أذكار المساء',
      );
      // Use go to ensure clean navigation from any state
      _navigateToRoute(route.location);
    }
  }

  /// Navigate to a route, catching errors in test environments
  void _navigateToRoute(String location) {
    try {
      AppRouter.router.push(location);
    } catch (e) {
      logger.w('[AthkarNotificationService] Navigation failed: $e');
    }
  }

  @visibleForTesting
  bool get isAndroid => Platform.isAndroid;
}
