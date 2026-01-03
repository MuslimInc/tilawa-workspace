import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
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
@lazySingleton
class AthkarNotificationService {
  AthkarNotificationService();

  /// Channel ID for athkar notifications
  static const String _athkarChannelId = 'com.tilawa.app.athkar';
  static const String _athkarChannelName = 'Athkar Reminders';
  static const String _athkarChannelDescription =
      'Daily reminders for morning and evening athkar';

  /// Notification IDs
  static const int _morningAthkarNotificationId = 1001;
  static const int _eveningAthkarNotificationId = 1002;

  FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @visibleForTesting
  set notifications(FlutterLocalNotificationsPlugin value) {
    _notifications = value;
  }

  bool _initialized = false;

  /// Initialize the notification service
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

      // Initialize notification plugin
      const androidSettings = AndroidInitializationSettings(
        'ic_launcher_monochrome',
      );
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: handleNotificationResponse,
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

  /// Get the local timezone name for the device
  Future<String?> _getLocalTimeZone() async {
    try {
      // For Android and iOS, we can try to get the system timezone
      // This is a simple approach - in production you might want to use
      // a package like flutter_native_timezone for more accuracy
      // For Android and iOS, we can try to get the system timezone
      // This is a simple approach - in production you might want to use
      // a package like flutter_native_timezone for more accuracy

      // Map common offsets to timezone names
      // This is simplified - you may want to use flutter_native_timezone
      // for production to get the exact timezone
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
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        color: Color(0xFF1AADC5),
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
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        color: Color(0xFF1AADC5),
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
        icon: 'ic_launcher_monochrome',
        largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
        color: Color(0xFF1AADC5),
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

  /// Cancel all athkar notifications
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

  /// Handle notification tap
  @visibleForTesting
  void handleNotificationResponse(NotificationResponse response) {
    logger.d('[AthkarNotificationService] Notification tapped: ${response.id}');

    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null) {
      logger.w('[AthkarNotificationService] Context is null, cannot navigate');
      return;
    }

    if (response.id == _morningAthkarNotificationId) {
      logger.d(
        '[AthkarNotificationService] Morning athkar notification tapped',
      );
      const AthkarDetailsRoute(
        categoryId: 1,
        categoryName: 'أذكار الصباح',
      ).go(context);
    } else if (response.id == _eveningAthkarNotificationId) {
      logger.d(
        '[AthkarNotificationService] Evening athkar notification tapped',
      );
      const AthkarDetailsRoute(
        categoryId: 2,
        categoryName: 'أذكار المساء',
      ).go(context);
    }
  }

  @visibleForTesting
  bool get isAndroid => Platform.isAndroid;
}
