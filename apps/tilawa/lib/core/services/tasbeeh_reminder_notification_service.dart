import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/config/android_notification_defaults.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_reminder_scheduler.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@LazySingleton(as: TasbeehReminderScheduler)
class TasbeehReminderNotificationService implements TasbeehReminderScheduler {
  TasbeehReminderNotificationService(
    this._prefs,
    this._dispatcher,
    this._navigationService,
  );

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  final NavigationService _navigationService;

  static const String _channelName = 'Tasbeeh reminders';
  static const String _channelDescription =
      'Daily reminders for your saved tasbeeh';

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  @override
  Future<void> scheduleReminder(TasbeehDhikr dhikr) async {
    if (!_canSchedule(dhikr)) {
      await cancelReminder(dhikr.id);
      return;
    }

    await _ensureInitialized();

    final int id = notificationIdFor(dhikr.id);
    final int hour = dhikr.reminderHour!;
    final int minute = dhikr.reminderMinute!;
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    try {
      final AppLocalizations l10n = await _localizations();
      await _notifications.zonedSchedule(
        id: id,
        title: dhikr.text,
        body: l10n.tasbeehReminderNotificationBody,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payloadFor(dhikr.id),
      );
      logger.d(
        '[TasbeehReminderNotificationService] Scheduled ${dhikr.id} at $scheduledDate',
      );
    } catch (e, stackTrace) {
      logger.e(
        '[TasbeehReminderNotificationService] Schedule failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelReminder(String dhikrId) async {
    await _ensureInitialized();
    try {
      await _notifications.cancel(id: notificationIdFor(dhikrId));
    } catch (e, stackTrace) {
      logger.e(
        '[TasbeehReminderNotificationService] Cancel failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelReminders(Iterable<String> dhikrIds) async {
    for (final String id in dhikrIds) {
      await cancelReminder(id);
    }
  }

  @override
  Future<void> ensureAllScheduled(Iterable<TasbeehDhikr> dhikr) async {
    if (!NotificationConfig.enableLocalNotifications) return;

    await _ensureInitialized();
    for (final item in dhikr) {
      if (_canSchedule(item)) {
        await scheduleReminder(item);
      } else {
        await cancelReminder(item.id);
      }
    }
  }

  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications || _initialized) return;

    try {
      tz.initializeTimeZones();
      await _configureLocalTimeZone();

      _dispatcher.registerPayloadHandler(
        serviceId: 'tasbeeh_reminder',
        matcher: _isTasbeehReminderPayload,
        handler: _handleNotificationResponse,
      );

      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            TasbeehConstants.reminderChannelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }

      _initialized = true;
      logger.d('[TasbeehReminderNotificationService] Initialized');
    } catch (e, stackTrace) {
      logger.e(
        '[TasbeehReminderNotificationService] Init failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static int notificationIdFor(String dhikrId) {
    return TasbeehConstants.reminderNotificationIdBase +
        (dhikrId.hashCode.abs() % TasbeehConstants.reminderNotificationIdRange);
  }

  static String payloadFor(String dhikrId) =>
      '${TasbeehConstants.reminderPayloadPrefix}$dhikrId';

  static String? dhikrIdFromPayload(String? payload) {
    if (payload == null ||
        !payload.startsWith(TasbeehConstants.reminderPayloadPrefix)) {
      return null;
    }
    final String id = payload.substring(
      TasbeehConstants.reminderPayloadPrefix.length,
    );
    return id.isEmpty ? null : id;
  }

  bool _canSchedule(TasbeehDhikr dhikr) {
    return dhikr.reminderEnabled &&
        dhikr.reminderHour != null &&
        dhikr.reminderMinute != null;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      final String resolvedTzName = info.identifier.isNotEmpty
          ? info.identifier
          : 'UTC';
      tz.setLocalLocation(tz.getLocation(resolvedTzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  bool _isTasbeehReminderPayload(String? payload) {
    return dhikrIdFromPayload(payload) != null;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final String? dhikrId = dhikrIdFromPayload(response.payload);
    if (dhikrId == null) return;

    const DeepLinkResolver resolver = DeepLinkResolver();
    try {
      _navigationService.routeToDestination(resolver.tasbeehDhikr(dhikrId));
    } catch (e) {
      logger.w('[TasbeehReminderNotificationService] Navigation failed: $e');
    }
  }

  Future<AppLocalizations> _localizations() async {
    String languageCode = LanguageConfig.defaultLanguageCode;
    try {
      languageCode =
          await _prefs.getString(LanguageConfig.languageKey) ?? languageCode;
    } catch (e) {
      logger.w(
        '[TasbeehReminderNotificationService] Failed to read locale: $e',
      );
    }
    return lookupAppLocalizations(Locale(languageCode));
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      TasbeehConstants.reminderChannelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: NotificationConfig.androidSmallIcon,
      color: AndroidNotificationDefaults.accentColor,
    ),
    iOS: DarwinNotificationDetails(),
  );
}
