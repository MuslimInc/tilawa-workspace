import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/config/android_notification_defaults.dart';
import 'package:tilawa/core/config/notification_config.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/constants/khatma_reminder_constants.dart';
import 'khatma_reminder_preferences.dart';

/// Schedules daily Khatma and curated Surah local reminders.
class KhatmaReminderNotificationService {
  KhatmaReminderNotificationService(
    this._prefs,
    this._dispatcher,
    this._navigationService,
  );

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  final NavigationService _navigationService;

  late final KhatmaReminderPreferences _settings = KhatmaReminderPreferences(
    _prefs,
  );

  static const String _dailyChannelName = 'Khatma reminders';
  static const String _dailyChannelDescription =
      'Daily reminders for your Khatma wird';
  static const String _surahChannelName = 'Surah reminders';
  static const String _surahChannelDescription =
      'Optional reminders for selected Surahs';

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  KhatmaReminderPreferences get preferences => _settings;

  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications || _initialized) return;

    try {
      tz.initializeTimeZones();
      await _configureLocalTimeZone();

      _dispatcher.registerPayloadHandler(
        serviceId: 'khatma_reminder',
        matcher: _isKhatmaPayload,
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
            KhatmaReminderConstants.dailyChannelId,
            _dailyChannelName,
            description: _dailyChannelDescription,
            importance: Importance.defaultImportance,
          ),
        );
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            KhatmaReminderConstants.surahChannelId,
            _surahChannelName,
            description: _surahChannelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }

      _initialized = true;
      await rescheduleFromPreferences();
      logger.d('[KhatmaReminderNotificationService] Initialized');
    } on Object catch (e, stackTrace) {
      logger.e(
        '[KhatmaReminderNotificationService] Init failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> enableDailyReminder({
    int hour = KhatmaReminderConstants.defaultHour,
    int minute = KhatmaReminderConstants.defaultMinute,
  }) async {
    await _settings.setDailyEnabled(enabled: true);
    await _settings.setDailyTime(hour: hour, minute: minute);
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  Future<void> disableDailyReminder() async {
    await _settings.setDailyEnabled(enabled: false);
    await cancelDailyReminder();
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) return;
    await _ensureInitialized();
    await _settings.setDailyTime(hour: hour, minute: minute);

    final AppLocalizations l10n = await _localizations();
    final tz.TZDateTime scheduled = _nextInstanceOfTime(hour, minute);
    try {
      await _notifications.zonedSchedule(
        id: KhatmaReminderConstants.dailyNotificationId,
        title: l10n.khatmaReminderNotificationTitle,
        body: l10n.khatmaReminderNotificationBody,
        scheduledDate: scheduled,
        notificationDetails: _dailyDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: KhatmaReminderConstants.dailyPayload,
      );
    } on Object catch (e, stackTrace) {
      logger.e(
        '[KhatmaReminderNotificationService] Daily schedule failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    try {
      await _notifications.cancel(
        id: KhatmaReminderConstants.dailyNotificationId,
      );
    } on Object catch (e, stackTrace) {
      logger.e(
        '[KhatmaReminderNotificationService] Daily cancel failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> enableBaqarahReminder() async {
    await _settings.setBaqarahEnabled(enabled: true);
    await scheduleBaqarahReminder();
  }

  Future<void> disableBaqarahReminder() async {
    await _settings.setBaqarahEnabled(enabled: false);
    await cancelBaqarahReminder();
  }

  Future<void> scheduleBaqarahReminder({
    int hour = KhatmaReminderConstants.defaultHour,
    int minute = 30,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) return;
    await _ensureInitialized();
    final AppLocalizations l10n = await _localizations();
    try {
      await _notifications.zonedSchedule(
        id: KhatmaReminderConstants.baqarahNotificationId,
        title: l10n.khatmaBaqarahReminderTitle,
        body: l10n.khatmaBaqarahReminderBody,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: _surahDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: KhatmaReminderConstants.baqarahPayload,
      );
    } on Object catch (e, stackTrace) {
      logger.e(
        '[KhatmaReminderNotificationService] Baqarah schedule failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelBaqarahReminder() async {
    await _ensureInitialized();
    try {
      await _notifications.cancel(
        id: KhatmaReminderConstants.baqarahNotificationId,
      );
    } on Object catch (_) {}
  }

  Future<void> enableKahfReminder() async {
    await _settings.setKahfEnabled(enabled: true);
    await scheduleKahfReminder();
  }

  Future<void> disableKahfReminder() async {
    await _settings.setKahfEnabled(enabled: false);
    await cancelKahfReminder();
  }

  Future<void> scheduleKahfReminder({
    int hour = KhatmaReminderConstants.defaultHour,
    int minute = 0,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) return;
    await _ensureInitialized();
    final AppLocalizations l10n = await _localizations();
    try {
      await _notifications.zonedSchedule(
        id: KhatmaReminderConstants.kahfNotificationId,
        title: l10n.khatmaKahfReminderTitle,
        body: l10n.khatmaKahfReminderBody,
        scheduledDate: _nextFridayAt(hour, minute),
        notificationDetails: _surahDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: KhatmaReminderConstants.kahfPayload,
      );
    } on Object catch (e, stackTrace) {
      logger.e(
        '[KhatmaReminderNotificationService] Kahf schedule failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelKahfReminder() async {
    await _ensureInitialized();
    try {
      await _notifications.cancel(
        id: KhatmaReminderConstants.kahfNotificationId,
      );
    } on Object catch (_) {}
  }

  Future<void> cancelAll() async {
    await cancelDailyReminder();
    await cancelBaqarahReminder();
    await cancelKahfReminder();
  }

  Future<void> clearOnPlanReset() async {
    await cancelAll();
    await _settings.clearAll();
  }

  Future<void> rescheduleFromPreferences() async {
    if (!NotificationConfig.enableLocalNotifications) return;
    if (await _settings.isDailyEnabled()) {
      await scheduleDailyReminder(
        hour: await _settings.dailyHour(),
        minute: await _settings.dailyMinute(),
      );
    } else {
      await cancelDailyReminder();
    }
    if (await _settings.isBaqarahEnabled()) {
      await scheduleBaqarahReminder();
    } else {
      await cancelBaqarahReminder();
    }
    if (await _settings.isKahfEnabled()) {
      await scheduleKahfReminder();
    } else {
      await cancelKahfReminder();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      final String resolvedTzName = info.identifier.isNotEmpty
          ? info.identifier
          : 'UTC';
      tz.setLocalLocation(tz.getLocation(resolvedTzName));
    } on Object catch (_) {
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
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextFridayAt(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != DateTime.friday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  bool _isKhatmaPayload(String? payload) {
    if (payload == null) return false;
    return payload == KhatmaReminderConstants.dailyPayload ||
        payload == KhatmaReminderConstants.baqarahPayload ||
        payload == KhatmaReminderConstants.kahfPayload;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final String? payload = response.payload;
    if (payload == null) return;
    const DeepLinkResolver resolver = DeepLinkResolver();
    try {
      if (payload == KhatmaReminderConstants.baqarahPayload) {
        _navigationService.routeToDestination(
          resolver.quranSurah(KhatmaReminderConstants.baqarahSurah),
        );
        return;
      }
      if (payload == KhatmaReminderConstants.kahfPayload) {
        _navigationService.routeToDestination(
          resolver.quranSurah(KhatmaReminderConstants.kahfSurah),
        );
        return;
      }
      _navigationService.routeToDestination(resolver.khatmaHub());
    } on Object catch (e) {
      logger.w('[KhatmaReminderNotificationService] Navigation failed: $e');
    }
  }

  Future<AppLocalizations> _localizations() async {
    String languageCode = LanguageConfig.defaultLanguageCode;
    try {
      languageCode =
          await _prefs.getString(LanguageConfig.languageKey) ?? languageCode;
    } on Object catch (e) {
      logger.w(
        '[KhatmaReminderNotificationService] Failed to read locale: $e',
      );
    }
    return lookupAppLocalizations(Locale(languageCode));
  }

  NotificationDetails get _dailyDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      KhatmaReminderConstants.dailyChannelId,
      _dailyChannelName,
      channelDescription: _dailyChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: NotificationConfig.androidSmallIcon,
      color: AndroidNotificationDefaults.accentColor,
    ),
    iOS: DarwinNotificationDetails(),
  );

  NotificationDetails get _surahDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      KhatmaReminderConstants.surahChannelId,
      _surahChannelName,
      channelDescription: _surahChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: NotificationConfig.androidSmallIcon,
      color: AndroidNotificationDefaults.accentColor,
    ),
    iOS: DarwinNotificationDetails(),
  );
}
