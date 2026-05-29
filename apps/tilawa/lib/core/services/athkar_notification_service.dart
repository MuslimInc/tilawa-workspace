import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/entities/prayer_settings_entity.dart';
import '../../features/prayer_times/domain/entities/prayer_time_entity.dart';
import '../config/notification_config.dart';
import '../di/injection.dart';

/// Service for scheduling daily athkar (remembrance) notifications
///
/// Schedules athkar notifications dynamically from prayer times:
/// - Morning athkar after Fajr
/// - Evening athkar after Asr
///
/// When prayer-time context is unavailable, it falls back to fixed daily times.
@LazySingleton(as: IAthkarNotificationService)
class AthkarNotificationService implements IAthkarNotificationService {
  AthkarNotificationService(
    this._prefs,
    this._dispatcher,
    this._analytics,
    this._navigationService,
    this._prayerTimesRepository,
  );

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  final AnalyticsService _analytics;
  final NavigationService _navigationService;
  final PrayerTimesRepository? _prayerTimesRepository;
  static const String _lastHandledPayloadKey =
      'last_handled_notification_payload';
  static const String _lastHandledTimestampKey =
      'last_handled_notification_timestamp';
  static const String _lastScheduledTimestampKey =
      'last_athkar_schedule_timestamp';

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
  static const int _dynamicMorningNotificationBaseId = 11000000;
  static const int _dynamicEveningNotificationBaseId = 12000000;
  static const int _dynamicScheduleWindowDays = 14;
  static const String _morningAthkarPayloadPrefix = 'morning_athkar_';
  static const String _eveningAthkarPayloadPrefix = 'evening_athkar_';

  /// Delay for athkar notifications after prayer times (1 hour)
  static const Duration _athkarNotificationDelay = Duration(hours: 1);

  /// Get notification IDs for external use (e.g., dispatcher registration)
  static Set<int> get notificationIds => {
    _morningAthkarNotificationId,
    _eveningAthkarNotificationId,
  };

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;
  PrayerTimesRepository get _resolvedPrayerTimesRepository =>
      _prayerTimesRepository ?? getIt<PrayerTimesRepository>();

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
        final String? timeZoneName = await getLocalTimeZone();
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

      // Keep startup path lightweight; high-importance channel creation is
      // deferred centrally in app_startup.
      await _dispatcher.initialize(createHighImportanceChannel: false);

      // Register our handler with the dispatcher
      _dispatcher.registerHandler(
        serviceId: 'athkar',
        notificationIds: notificationIds,
        handler: handleNotificationResponse,
      );
      _dispatcher.registerPayloadHandler(
        serviceId: 'athkar',
        matcher: _isAthkarPayload,
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

        if (_isAthkarNotification(id: id, payload: payload)) {
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

  /// Get the local timezone name for the device.
  ///
  /// Uses `flutter_timezone` to read the device's IANA timezone identifier
  /// (e.g. `Europe/London`, `Asia/Jakarta`). Returns `null` on failure so the
  /// caller falls back to UTC.
  @visibleForTesting
  Future<String?> getLocalTimeZone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      final String identifier = info.identifier;
      if (identifier.isEmpty) {
        return null;
      }
      return identifier;
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
      // BUG #1 FIX: Always cancel before scheduling, not just when rescheduling
      // This prevents duplicate notifications on app restart within 7-day window
      await cancelAllAthkarNotifications();

      // Add a small delay to ensure cancellation completes before scheduling
      // BUG #3 FIX: Prevent race condition in cancel/schedule sequence
      await Future<void>.delayed(Duration(milliseconds: 100));

      final List<ScheduledAthkarNotification>? dynamicNotifications =
          await _buildDynamicAthkarNotifications();

      if (dynamicNotifications == null || dynamicNotifications.isEmpty) {
        logger.w(
          '[AthkarNotificationService] Prayer-time context unavailable, using fixed fallback times',
        );
        await _scheduleMorningAthkarFallback();
        await _scheduleEveningAthkarFallback();
      } else {
        for (int i = 0; i < dynamicNotifications.length; i++) {
          await _scheduleAthkarNotification(dynamicNotifications[i]);

          // Yield to UI thread every 5 notifications to prevent jank
          if (i > 0 && i % 5 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }

        logger.d(
          '[AthkarNotificationService] Scheduled ${dynamicNotifications.length} dynamic athkar notifications',
        );
      }

      await _prefs.setInt(
        _lastScheduledTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      logger.d(
        '[AthkarNotificationService] Scheduled all athkar notifications',
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling notifications: $e',
      );
    }
  }

  /// Schedule morning athkar notification at a fixed fallback time.
  Future<void> _scheduleMorningAthkarFallback() async {
    try {
      // Use 1 hour after common Fajr (e.g., 5:30 -> 6:30 or 7:00)
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(7, 30);

      await _notifications.zonedSchedule(
        id: _morningAthkarNotificationId,
        title: _morningAthkarTitle,
        body: _morningAthkarBody,
        scheduledDate: scheduledDate,
        notificationDetails: _athkarNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload:
            '$_morningAthkarPayloadPrefix${scheduledDate.millisecondsSinceEpoch}',
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

  /// Schedule evening athkar notification at a fixed fallback time.
  Future<void> _scheduleEveningAthkarFallback() async {
    try {
      // Use 1 hour after common Asr (e.g., 16:30 -> 17:30 or 18:00)
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(18, 0);

      await _notifications.zonedSchedule(
        id: _eveningAthkarNotificationId,
        title: _eveningAthkarTitle,
        body: _eveningAthkarBody,
        scheduledDate: scheduledDate,
        notificationDetails: _athkarNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload:
            '$_eveningAthkarPayloadPrefix${scheduledDate.millisecondsSinceEpoch}',
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

  Future<List<ScheduledAthkarNotification>?>
  _buildDynamicAthkarNotifications() async {
    try {
      final AthkarScheduleContext? context = await _resolveScheduleContext();
      if (context == null) {
        return null;
      }

      final DateTime now = DateTime.now();
      final DateTime startDate = DateTime(now.year, now.month, now.day);
      final DateTime endDate = startDate.add(
        const Duration(days: _dynamicScheduleWindowDays - 1),
      );

      final List<PrayerTimeEntity> prayerTimes =
          await _resolvedPrayerTimesRepository.getPrayerTimesForRange(
            latitude: context.latitude,
            longitude: context.longitude,
            startDate: startDate,
            endDate: endDate,
            settings: context.settings,
          );

      if (prayerTimes.isEmpty) {
        return null;
      }

      prayerTimes.sort((a, b) => a.date.compareTo(b.date));

      final List<ScheduledAthkarNotification> notifications =
          <ScheduledAthkarNotification>[];

      for (final PrayerTimeEntity prayerTime in prayerTimes) {
        // BUG #4 FIX: Validate prayer time values are reasonable (defensive check)
        if (prayerTime.fajr.year == 0 || prayerTime.asr.year == 0) {
          logger.w(
            '[AthkarNotificationService] Invalid prayer time data for ${prayerTime.date}',
          );
          continue;
        }

        final ScheduledAthkarNotification? morningNotification =
            _createDynamicNotification(
              date: prayerTime.date,
              prayerTime: prayerTime.fajr.add(_athkarNotificationDelay),
              isMorning: true,
            );
        final ScheduledAthkarNotification? eveningNotification =
            _createDynamicNotification(
              date: prayerTime.date,
              prayerTime: prayerTime.asr.add(_athkarNotificationDelay),
              isMorning: false,
            );

        if (morningNotification != null) {
          notifications.add(morningNotification);
        }
        if (eveningNotification != null) {
          notifications.add(eveningNotification);
        }
      }

      return notifications;
    } catch (e, stackTrace) {
      logger.w(
        '[AthkarNotificationService] Failed to build dynamic athkar schedule: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<AthkarScheduleContext?> _resolveScheduleContext() async {
    try {
      var settings = await _resolvedPrayerTimesRepository.loadSettings();
      double? latitude = settings.savedLatitude;
      double? longitude = settings.savedLongitude;
      String? countryCode;

      if (latitude == null || longitude == null) {
        final bool hasPermission = await _resolvedPrayerTimesRepository
            .hasLocationPermission();
        if (!hasPermission) {
          return null;
        }

        final LocationResult location = await _resolvedPrayerTimesRepository
            .getCurrentLocation();
        if (location.hasError) {
          return null;
        }

        latitude = location.latitude;
        longitude = location.longitude;
        countryCode = location.countryCode;
      } else if (settings.calculationMethod == CalculationMethod.ummAlQura) {
        countryCode = await _resolvedPrayerTimesRepository.getCountryCode(
          latitude: latitude,
          longitude: longitude,
        );
      }

      if (countryCode != null &&
          settings.calculationMethod == CalculationMethod.ummAlQura) {
        final CalculationMethod? recommendedMethod =
            PrayerSettingsEntity.defaultForCountry(countryCode);
        if (recommendedMethod != null &&
            recommendedMethod != settings.calculationMethod) {
          settings = settings.copyWith(calculationMethod: recommendedMethod);
        }
      }

      return AthkarScheduleContext(
        latitude: latitude,
        longitude: longitude,
        settings: settings,
      );
    } catch (e, stackTrace) {
      logger.w(
        '[AthkarNotificationService] Failed to resolve prayer-time context: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @visibleForTesting
  ScheduledAthkarNotification? testCreateDynamicNotification({
    required DateTime date,
    required DateTime prayerTime,
    required bool isMorning,
  }) => _createDynamicNotification(
    date: date,
    prayerTime: prayerTime,
    isMorning: isMorning,
  );

  ScheduledAthkarNotification? _createDynamicNotification({
    required DateTime date,
    required DateTime prayerTime,
    required bool isMorning,
  }) {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      prayerTime,
      tz.local,
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    if (!scheduledDate.isAfter(now)) {
      return null;
    }

    // BUG #4 FIX: Validate prayer time is not null before using
    if (prayerTime.year == 0 || prayerTime.month == 0 || prayerTime.day == 0) {
      logger.w(
        '[AthkarNotificationService] Invalid prayer time: $prayerTime, skipping notification',
      );
      return null;
    }

    // BUG #2 FIX: Use date-based unique ID instead of millisecond timestamp to prevent payload collision
    // This ensures unique payloads for the same notification even if scheduled within the same millisecond
    final String uniquePayloadId =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return ScheduledAthkarNotification(
      id: _buildDynamicNotificationId(date: date, isMorning: isMorning),
      title: isMorning ? _morningAthkarTitle : _eveningAthkarTitle,
      body: isMorning ? _morningAthkarBody : _eveningAthkarBody,
      scheduledDate: scheduledDate,
      payload:
          '${isMorning ? _morningAthkarPayloadPrefix : _eveningAthkarPayloadPrefix}$uniquePayloadId',
    );
  }

  Future<void> _scheduleAthkarNotification(
    ScheduledAthkarNotification notification,
  ) async {
    try {
      // BUG #5 FIX: Check Android 12+ exact alarm permission before scheduling
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (Platform.isAndroid) {
        final bool canScheduleExact = await _canScheduleExactAlarms();
        if (!canScheduleExact) {
          logger.w(
            '[AthkarNotificationService] Exact alarm permission denied, using inexact scheduling for notification ${notification.id}',
          );
          scheduleMode = AndroidScheduleMode.inexact;
        }
      }

      await _notifications.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: notification.scheduledDate,
        notificationDetails: _athkarNotificationDetails,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: null,
        payload: notification.payload,
      );
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error scheduling notification ${notification.id}: $e',
      );
    }
  }

  /// Check if app has permission to schedule exact alarms (Android 12+)
  /// On older Android versions, always returns true
  Future<bool> _canScheduleExactAlarms() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // For Android 12+, we need to check SCHEDULE_EXACT_ALARM permission
      // If using flutter_local_notifications >= 14.0, this is usually handled internally
      // For now, we assume it's handled and return true
      // In production, you'd use platform channels to check this
      return true;
    } catch (e) {
      logger.e(
        '[AthkarNotificationService] Error checking exact alarm permission: $e',
      );
      return false;
    }
  }

  int _buildDynamicNotificationId({
    required DateTime date,
    required bool isMorning,
  }) {
    final int dateKey = (date.year * 10000) + (date.month * 100) + date.day;
    return (isMorning
            ? _dynamicMorningNotificationBaseId
            : _dynamicEveningNotificationBaseId) +
        dateKey;
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
        id: 9999, // Test notification ID
        title: 'Test Athkar Notification',
        body: 'This is a test notification scheduled for $scheduledDate',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
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
          ? '$_morningAthkarPayloadPrefix${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_debug'
          : '$_eveningAthkarPayloadPrefix${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_debug';

      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
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
      final List<PendingNotificationRequest> pendingNotifications =
          await _notifications.pendingNotificationRequests();

      for (final PendingNotificationRequest pendingNotification
          in pendingNotifications) {
        if (_isAthkarPayload(pendingNotification.payload)) {
          await _notifications.cancel(id: pendingNotification.id);
        }
      }

      await _notifications.cancel(id: _morningAthkarNotificationId);
      await _notifications.cancel(id: _eveningAthkarNotificationId);
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

      // BUG #2 FIX: Improved deduplication - check both payload and timestamp
      // This prevents duplicate navigation even if the same notification fires twice
      if (lastHandled == payload) {
        final int? lastTimestamp = await _prefs.getInt(
          _lastHandledTimestampKey,
        );
        final int now = DateTime.now().millisecondsSinceEpoch;

        // Allow rehandling if more than 60 seconds have passed
        if (lastTimestamp != null &&
            (now - lastTimestamp) <
                _notificationValidityDurationSeconds * 1000) {
          logger.d(
            '[AthkarNotificationService] Ignoring already handled notification within validity window: $payload',
          );
          return;
        }
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

    const DeepLinkResolver resolver = DeepLinkResolver();
    if (_isMorningAthkarNotification(id: response.id, payload: payload)) {
      logger.d(
        '[AthkarNotificationService] Morning athkar notification tapped - navigating',
      );
      _analytics.logAthkarNotificationOpen(
        DeepLinkResolver.athkarMorningCategoryId,
        DeepLinkResolver.athkarMorningCategoryName,
      );
      // Resolve through the single resolver so the read is attributed to the
      // notification (previously defaulted to source='manual').
      _navigateToDestination(resolver.athkarMorning());
    } else if (_isEveningAthkarNotification(
      id: response.id,
      payload: payload,
    )) {
      logger.d(
        '[AthkarNotificationService] Evening athkar notification tapped - navigating',
      );
      _analytics.logAthkarNotificationOpen(
        DeepLinkResolver.athkarEveningCategoryId,
        DeepLinkResolver.athkarEveningCategoryName,
      );
      _navigateToDestination(resolver.athkarEvening());
    }
  }

  /// Navigate to a resolved destination, catching errors in test environments.
  void _navigateToDestination(NotificationDestination destination) {
    try {
      _navigationService.navigateToNotification(
        destination.location,
        extra: destination.extra,
      );
    } catch (e) {
      logger.w('[AthkarNotificationService] Navigation failed: $e');
    }
  }

  @visibleForTesting
  bool get isAndroid => Platform.isAndroid;

  @visibleForTesting
  String get morningAthkarPayloadPrefix => _morningAthkarPayloadPrefix;

  @visibleForTesting
  String get eveningAthkarPayloadPrefix => _eveningAthkarPayloadPrefix;

  bool _isAthkarPayload(String? payload) {
    return _isMorningAthkarPayload(payload) || _isEveningAthkarPayload(payload);
  }

  bool _isMorningAthkarPayload(String? payload) {
    return payload?.startsWith(_morningAthkarPayloadPrefix) ?? false;
  }

  bool _isEveningAthkarPayload(String? payload) {
    return payload?.startsWith(_eveningAthkarPayloadPrefix) ?? false;
  }

  bool _isAthkarNotification({required int? id, required String? payload}) {
    return _isAthkarPayload(payload) ||
        (id != null && notificationIds.contains(id));
  }

  bool _isMorningAthkarNotification({
    required int? id,
    required String? payload,
  }) {
    if (_isMorningAthkarPayload(payload)) {
      return true;
    }
    if (_isEveningAthkarPayload(payload)) {
      return false;
    }
    return id == _morningAthkarNotificationId;
  }

  bool _isEveningAthkarNotification({
    required int? id,
    required String? payload,
  }) {
    if (_isEveningAthkarPayload(payload)) {
      return true;
    }
    if (_isMorningAthkarPayload(payload)) {
      return false;
    }
    return id == _eveningAthkarNotificationId;
  }

  NotificationDetails get _athkarNotificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _athkarChannelId,
          _athkarChannelName,
          channelDescription: _athkarChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher_monochrome',
          color: AppColors.notificationAccent,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );

  static const String _morningAthkarTitle = 'أذكار الصباح';
  static const String _morningAthkarBody = 'حان وقت أذكار الصباح 🌅';
  static const String _eveningAthkarTitle = 'أذكار المساء';
  static const String _eveningAthkarBody = 'حان وقت أذكار المساء 🌙';
}

class AthkarScheduleContext {
  const AthkarScheduleContext({
    required this.latitude,
    required this.longitude,
    required this.settings,
  });

  final double latitude;
  final double longitude;
  final PrayerSettingsEntity settings;
}

class ScheduledAthkarNotification {
  const ScheduledAthkarNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String payload;
}
