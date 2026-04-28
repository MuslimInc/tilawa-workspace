import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/entities/prayer_settings_entity.dart';
import '../../features/prayer_times/domain/entities/prayer_time_entity.dart';
import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import '../../features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import '../../router/app_router_config.dart';
import '../config/notification_config.dart';
import 'notification_permission_service.dart';
import 'prayer_notification_config.dart';

/// Five prayers that participate in scheduled notifications. Sunrise, midnight
/// and lastThird have no [PrayerNotificationSettings] field on
/// [PrayerSettingsEntity] and are not user-configurable, so they are excluded.
const List<PrayerType> _schedulablePrayers = [
  PrayerType.fajr,
  PrayerType.dhuhr,
  PrayerType.asr,
  PrayerType.maghrib,
  PrayerType.isha,
];

@LazySingleton(as: IPrayerAdhanNotificationService)
class PrayerAdhanNotificationService
    implements IPrayerAdhanNotificationService {
  PrayerAdhanNotificationService(
    this._prefs,
    this._dispatcher,
    this._navigationService,
    this._analytics,
    this._adhanPlayer,
    this._notificationPermissionService,
  );

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  final NavigationService _navigationService;
  final AnalyticsService _analytics;
  final IAdhanAlarmPlayer _adhanPlayer;
  final NotificationPermissionService _notificationPermissionService;

  bool _initialized = false;

  /// Set on the next [schedulePrayerNotifications] call when [initialize]
  /// detects the device timezone has changed since the last scheduling run.
  bool _pendingForceReschedule = false;

  FlutterLocalNotificationsPlugin get _notifications =>
      _dispatcher.notificationsPlugin;

  @override
  Future<void> initialize() async {
    if (!NotificationConfig.enableLocalNotifications) {
      logger.d(
        '${PrayerNotificationConfig.logTag} Notifications disabled in config',
      );
      return;
    }

    if (_initialized) {
      logger.d('${PrayerNotificationConfig.logTag} Already initialized');
      return;
    }

    try {
      tz.initializeTimeZones();

      String resolvedTzName = 'UTC';
      try {
        final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
        if (info.identifier.isNotEmpty) {
          resolvedTzName = info.identifier;
        }
        tz.setLocalLocation(tz.getLocation(resolvedTzName));
        logger.d(
          '${PrayerNotificationConfig.logTag} Timezone set to: $resolvedTzName',
        );
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Error setting timezone: $e, using UTC',
        );
        tz.setLocalLocation(tz.UTC);
        resolvedTzName = 'UTC';
      }

      // Detect timezone change since last run; if changed, force the next
      // scheduling pass to bypass dedup so alarms recompute against the new
      // local time.
      try {
        final String? lastTz = await _prefs.getString(
          PrayerNotificationConfig.lastTimezoneKey,
        );
        if (lastTz != null && lastTz != resolvedTzName) {
          _pendingForceReschedule = true;
          logger.d(
            '${PrayerNotificationConfig.logTag} Timezone changed ($lastTz -> $resolvedTzName); forcing next reschedule',
          );
        }
        await _prefs.setString(
          PrayerNotificationConfig.lastTimezoneKey,
          resolvedTzName,
        );
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Failed to read/persist timezone fingerprint: $e',
        );
      }

      // Lightweight init — high-importance channel creation is owned by the
      // central app startup path.
      await _dispatcher.initialize(createHighImportanceChannel: false);

      _dispatcher.registerHandler(
        serviceId: 'prayer_notifications',
        notificationIds: _staticNotificationIds,
        handler: handleNotificationResponse,
      );
      _dispatcher.registerPayloadHandler(
        serviceId: 'prayer_notifications',
        matcher: _isPrayerPayload,
        handler: handleNotificationResponse,
      );

      if (Platform.isAndroid) {
        await _createAndroidChannels();
      }

      _initialized = true;
      logger.d('${PrayerNotificationConfig.logTag} Initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        '${PrayerNotificationConfig.logTag} Initialization failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _createAndroidChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return;
    }
    final AppLocalizations l10n = await _localizations();

    // Default-sound channel (unchanged)
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        PrayerNotificationConfig.channelId,
        l10n.prayerNotificationsChannelName,
        description: l10n.prayerNotificationsChannelDescription,
        importance: Importance.high,
      ),
    );

    // Adhan channel: delete and recreate when the version key changes so the
    // custom sound asset is picked up on existing installs (Android locks
    // channel sound after first creation).
    final int? installedVersion = await _prefs.getInt(
      PrayerNotificationConfig.adhanChannelVersionKey,
    );
    if (installedVersion != PrayerNotificationConfig.adhanChannelVersion) {
      await androidPlugin.deleteNotificationChannel(
        channelId: PrayerNotificationConfig.adhanChannelId,
      );
      logger.d(
        '${PrayerNotificationConfig.logTag} Adhan channel upgraded to v${PrayerNotificationConfig.adhanChannelVersion}',
      );
    }
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        PrayerNotificationConfig.adhanChannelId,
        l10n.prayerNotificationsAdhanChannelName,
        description: l10n.prayerNotificationsAdhanChannelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(
          PrayerNotificationConfig.adhanSoundRawName,
        ),
        playSound: true,
      ),
    );
    await _prefs.setInt(
      PrayerNotificationConfig.adhanChannelVersionKey,
      PrayerNotificationConfig.adhanChannelVersion,
    );
  }

  Set<int> get _staticNotificationIds =>
      _schedulablePrayers.map(PrayerNotificationConfig.staticId).toSet();

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  }) async {
    if (!NotificationConfig.enableLocalNotifications) {
      logger.d(
        '${PrayerNotificationConfig.logTag} Notifications disabled — skipping schedule',
      );
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      final bool effectiveForce = forceReschedule || _pendingForceReschedule;
      _pendingForceReschedule = false;

      if (prayerTimesForDays.isEmpty) {
        logger.w(
          '${PrayerNotificationConfig.logTag} No prayer times provided — schedule skipped',
        );
        return;
      }

      final bool hasNotificationPermission =
          await _notificationPermissionService.isPermissionGranted();
      if (!hasNotificationPermission) {
        await _clearDedupState();
        logger.w(
          '${PrayerNotificationConfig.logTag} Notification permission denied — scheduling suppressed',
        );
        return;
      }

      // Dedup
      final String today = _todayDateKey();
      final String currentFingerprint = _computeFingerprint(
        settings: settings,
        prayerTimesForDays: prayerTimesForDays,
      );
      if (!effectiveForce) {
        final String? storedDate = await _prefs.getString(
          PrayerNotificationConfig.dedupDateKey,
        );
        final String? storedFingerprint = await _prefs.getString(
          PrayerNotificationConfig.settingsFingerprintKey,
        );
        if (storedDate == today && storedFingerprint == currentFingerprint) {
          logger.d(
            '${PrayerNotificationConfig.logTag} Dedup hit — already scheduled for $today (fingerprint match)',
          );
          return;
        }
      }

      // Cancel previous schedule before installing the new one. Idempotent.
      await cancelAllPrayerNotifications();

      final bool canScheduleExact = await canScheduleExactAlarms();
      final AndroidScheduleMode scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact;
      if (!canScheduleExact) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Exact alarm permission denied — using inexact mode',
        );
      }

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final AppLocalizations l10n = await _localizations();
      final int dayCount =
          prayerTimesForDays.length < PrayerNotificationConfig.scheduleDaysAhead
          ? prayerTimesForDays.length
          : PrayerNotificationConfig.scheduleDaysAhead;

      int scheduled = 0;
      for (int dayOffset = 0; dayOffset < dayCount; dayOffset++) {
        final PrayerTimeEntity dayTimes = prayerTimesForDays[dayOffset];

        for (final PrayerType prayer in _schedulablePrayers) {
          final PrayerNotificationSettings prayerSettings = _settingsFor(
            settings,
            prayer,
          );
          if (!prayerSettings.enabled) {
            continue;
          }

          final DateTime prayerTime = _prayerDateTime(dayTimes, prayer);
          final DateTime targetTime = prayerTime.subtract(
            Duration(minutes: prayerSettings.minutesBefore),
          );
          final tz.TZDateTime tzTarget = tz.TZDateTime.from(
            targetTime,
            tz.local,
          );

          if (!tzTarget.isAfter(now)) {
            logger.d(
              '${PrayerNotificationConfig.logTag} Skipping $prayer ${_dateKey(dayTimes.date)} — time in past',
            );
            continue;
          }

          final int notificationId = PrayerNotificationConfig.dynamicId(
            dayOffset,
            prayer,
          );
          final String payload = jsonEncode({
            PrayerNotificationConfig.payloadTypeKey:
                PrayerNotificationConfig.payloadTypeValue,
            PrayerNotificationConfig.payloadPrayerKey: prayer.name,
            PrayerNotificationConfig.payloadDateKey: _dateKey(dayTimes.date),
          });

          final bool useAdhan = prayerSettings.playAdhan;
          final String channelUsed = useAdhan
              ? PrayerNotificationConfig.adhanChannelId
              : PrayerNotificationConfig.channelId;
          logger.d(
            '${PrayerNotificationConfig.logTag} [SCHEDULE] ${prayer.name} '
            'day+$dayOffset id=$notificationId at $tzTarget | '
            'channel=$channelUsed | adhan=$useAdhan | '
            'mode=${canScheduleExact ? 'exact' : 'inexact'}',
          );

          try {
            await _notifications.zonedSchedule(
              id: notificationId,
              title: _titleFor(l10n, prayer),
              body: _bodyFor(l10n, prayer),
              scheduledDate: tzTarget,
              notificationDetails: _detailsFor(l10n, useAdhan),
              androidScheduleMode: scheduleMode,
              matchDateTimeComponents: null,
              payload: payload,
            );
            scheduled++;
            logger.d(
              '${PrayerNotificationConfig.logTag} [SCHEDULE OK] ${prayer.name} '
              '${_dateKey(dayTimes.date)} scheduled successfully '
              '(${canScheduleExact ? 'exact' : 'inexact'} | adhan=$useAdhan)',
            );
          } catch (e) {
            logger.e(
              '${PrayerNotificationConfig.logTag} [SCHEDULE FAIL] ${prayer.name} '
              '${_dateKey(dayTimes.date)} id=$notificationId: $e',
            );
          }

          logger.d(
            '${PrayerNotificationConfig.logTag} [ADHAN CHECK] ${prayer.name} '
            'playAdhan=$useAdhan | adhanPlayer.isSupported=${_adhanPlayer.isSupported}',
          );
          if (useAdhan && _adhanPlayer.isSupported) {
            try {
              await _adhanPlayer.scheduleAdhan(
                id: notificationId,
                scheduledTime: targetTime,
                prayerName: prayer.name,
              );
              logger.d(
                '${PrayerNotificationConfig.logTag} [ADHAN SCHEDULED] ${prayer.name} via adhanPlayer',
              );
            } catch (e) {
              logger.e(
                '${PrayerNotificationConfig.logTag} [ADHAN FAIL] adhanPlayer.scheduleAdhan failed for ${prayer.name}: $e',
              );
            }
          } else if (useAdhan) {
            logger.d(
              '${PrayerNotificationConfig.logTag} [ADHAN] ${prayer.name}: adhanPlayer not supported — '
              'relying on notification channel sound (${PrayerNotificationConfig.adhanSoundRawName})',
            );
          } else {
            logger.d(
              '${PrayerNotificationConfig.logTag} [ADHAN] ${prayer.name}: adhan disabled — '
              'default notification sound will play',
            );
          }

          // Yield every 5 schedules to avoid blocking the UI thread (mirrors
          // the athkar service jank-prevention pattern).
          if (scheduled > 0 && scheduled % 5 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }

      try {
        await _prefs.setString(PrayerNotificationConfig.dedupDateKey, today);
        await _prefs.setString(
          PrayerNotificationConfig.settingsFingerprintKey,
          currentFingerprint,
        );
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Failed to persist dedup state: $e',
        );
      }

      logger.d(
        '${PrayerNotificationConfig.logTag} Scheduled $scheduled prayer notifications',
      );
    } catch (e, stackTrace) {
      logger.e(
        '${PrayerNotificationConfig.logTag} Error scheduling notifications: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelAllPrayerNotifications() async {
    if (!NotificationConfig.enableLocalNotifications) {
      return;
    }
    try {
      // Static IDs (debug/test slot)
      for (final PrayerType prayer in _schedulablePrayers) {
        await _notifications.cancel(
          id: PrayerNotificationConfig.staticId(prayer),
        );
      }
      // Dynamic IDs across the schedule window. Iterate every prayer slot in
      // the window — cheaper and deterministic vs. filtering pendingNotifications.
      int cancelled = 0;
      for (
        int dayOffset = 0;
        dayOffset < PrayerNotificationConfig.scheduleDaysAhead;
        dayOffset++
      ) {
        for (final PrayerType prayer in _schedulablePrayers) {
          await _notifications.cancel(
            id: PrayerNotificationConfig.dynamicId(dayOffset, prayer),
          );
          cancelled++;
        }
      }
      try {
        await _adhanPlayer.cancelAllAdhans();
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Adhan player cancelAll failed: $e',
        );
      }
      logger.d(
        '${PrayerNotificationConfig.logTag} Cancelled $cancelled dynamic alarm IDs',
      );
    } catch (e, stackTrace) {
      logger.e(
        '${PrayerNotificationConfig.logTag} Error cancelling notifications: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) {
      return true;
    }
    try {
      final AndroidFlutterLocalNotificationsPlugin? impl = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await impl?.canScheduleExactNotifications() ?? true;
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} canScheduleExactAlarms failed: $e',
      );
      // Fail-open: let the schedule path attempt; the OS will reject if needed.
      return true;
    }
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final AndroidFlutterLocalNotificationsPlugin? impl = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await impl?.requestExactAlarmsPermission();
    } catch (e) {
      logger.e(
        '${PrayerNotificationConfig.logTag} requestExactAlarmPermission failed: $e',
      );
    }
  }

  @override
  Future<void> fireTestNotification({
    required PrayerType prayer,
    required bool playAdhan,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      final int testId = PrayerNotificationConfig.staticId(prayer);
      final String payload = jsonEncode({
        PrayerNotificationConfig.payloadTypeKey:
            PrayerNotificationConfig.payloadTypeValue,
        PrayerNotificationConfig.payloadPrayerKey: prayer.name,
        PrayerNotificationConfig.payloadDateKey: _todayDateKey(),
      });
      final String channelUsed = playAdhan
          ? PrayerNotificationConfig.adhanChannelId
          : PrayerNotificationConfig.channelId;
      final String soundFile = playAdhan
          ? PrayerNotificationConfig.adhanSoundRawName
          : 'default';
      final AppLocalizations l10n = await _localizations();
      logger.d(
        '${PrayerNotificationConfig.logTag} [TEST] Firing test notification | '
        'prayer=${prayer.name} | playAdhan=$playAdhan | '
        'channel=$channelUsed | sound=$soundFile | id=$testId',
      );
      await _notifications.show(
        id: testId,
        title: _titleFor(l10n, prayer),
        body: _bodyFor(l10n, prayer),
        notificationDetails: _detailsFor(l10n, playAdhan),
        payload: payload,
      );
      logger.d(
        '${PrayerNotificationConfig.logTag} [TEST OK] Notification delivered to system | '
        'prayer=${prayer.name} | channel=$channelUsed | sound=$soundFile',
      );
      logger.d(
        '${PrayerNotificationConfig.logTag} [ADHAN CHECK] adhanPlayer.isSupported=${_adhanPlayer.isSupported} | '
        'playAdhan=$playAdhan — '
        '${playAdhan && _adhanPlayer.isSupported
            ? 'adhanPlayer will play'
            : playAdhan
            ? 'channel sound (${PrayerNotificationConfig.adhanSoundRawName}) will play'
            : 'default sound will play'}',
      );
    } catch (e, st) {
      logger.e(
        '${PrayerNotificationConfig.logTag} fireTestNotification failed: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    try {
      final String? payload = response.payload;
      if (payload == null || !_isPrayerPayload(payload)) {
        return;
      }

      String? prayerName;
      try {
        final dynamic decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          final dynamic v = decoded[PrayerNotificationConfig.payloadPrayerKey];
          if (v is String) {
            prayerName = v;
          }
        }
      } catch (_) {
        // Best-effort decode; fall through with prayerName == null.
      }

      try {
        final Map<String, Object> params = <String, Object>{};
        if (prayerName != null) {
          params['prayer'] = prayerName;
        }
        final int? id = response.id;
        if (id != null) {
          params['notification_id'] = id;
        }
        await _analytics.logEvent(
          'prayer_notification_open',
          parameters: params,
        );
      } catch (e) {
        logger.w('${PrayerNotificationConfig.logTag} Analytics log failed: $e');
      }

      _navigateToPrayerTimes();
    } catch (e, stackTrace) {
      logger.e(
        '${PrayerNotificationConfig.logTag} handleNotificationResponse failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _navigateToPrayerTimes() {
    try {
      _navigationService.navigateToNotification(
        const PrayerTimesRoute().location,
      );
    } catch (e) {
      logger.w('${PrayerNotificationConfig.logTag} Navigation failed: $e');
    }
  }

  // -- helpers ----------------------------------------------------------------

  bool _isPrayerPayload(String? payload) {
    if (payload == null || payload.isEmpty) return false;
    // Cheap structural check; keeps the dispatcher matcher allocation-free.
    return payload.contains(
      '"${PrayerNotificationConfig.payloadTypeKey}":"'
      '${PrayerNotificationConfig.payloadTypeValue}"',
    );
  }

  PrayerNotificationSettings _settingsFor(
    PrayerSettingsEntity settings,
    PrayerType prayer,
  ) {
    switch (prayer) {
      case PrayerType.fajr:
        return settings.fajrNotification;
      case PrayerType.dhuhr:
        return settings.dhuhrNotification;
      case PrayerType.asr:
        return settings.asrNotification;
      case PrayerType.maghrib:
        return settings.maghribNotification;
      case PrayerType.isha:
        return settings.ishaNotification;
      case PrayerType.sunrise:
      case PrayerType.midnight:
      case PrayerType.lastThird:
        return const PrayerNotificationSettings(enabled: false);
    }
  }

  DateTime _prayerDateTime(PrayerTimeEntity day, PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return day.fajr;
      case PrayerType.sunrise:
        return day.sunrise;
      case PrayerType.dhuhr:
        return day.dhuhr;
      case PrayerType.asr:
        return day.asr;
      case PrayerType.maghrib:
        return day.maghrib;
      case PrayerType.isha:
        return day.isha;
      case PrayerType.midnight:
        return day.midnight;
      case PrayerType.lastThird:
        return day.lastThird;
    }
  }

  String _titleFor(AppLocalizations l10n, PrayerType prayer) {
    return _localizedPrayerName(l10n, prayer);
  }

  String _bodyFor(AppLocalizations l10n, PrayerType prayer) {
    return l10n.prayerNotificationBody(_localizedPrayerName(l10n, prayer));
  }

  NotificationDetails _detailsFor(AppLocalizations l10n, bool playAdhan) {
    final String channelId = playAdhan
        ? PrayerNotificationConfig.adhanChannelId
        : PrayerNotificationConfig.channelId;
    final String channelName = playAdhan
        ? l10n.prayerNotificationsAdhanChannelName
        : l10n.prayerNotificationsChannelName;
    final String channelDescription = playAdhan
        ? l10n.prayerNotificationsAdhanChannelDescription
        : l10n.prayerNotificationsChannelDescription;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher_monochrome',
        color: AppColors.notificationAccent,
        sound: playAdhan
            ? RawResourceAndroidNotificationSound(
                PrayerNotificationConfig.adhanSoundRawName,
              )
            : null,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: playAdhan
            ? PrayerNotificationConfig.adhanSoundFilename
            : 'default',
      ),
    );
  }

  String _todayDateKey() {
    final DateTime now = DateTime.now();
    return _dateKey(now);
  }

  Future<void> _clearDedupState() async {
    try {
      await _prefs.remove(PrayerNotificationConfig.dedupDateKey);
      await _prefs.remove(PrayerNotificationConfig.settingsFingerprintKey);
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} Failed to clear dedup state: $e',
      );
    }
  }

  Future<AppLocalizations> _localizations() async {
    String languageCode = LanguageConfig.defaultLanguageCode;
    try {
      languageCode =
          await _prefs.getString(LanguageConfig.languageKey) ?? languageCode;
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} Failed to read locale preference: $e',
      );
    }
    return lookupAppLocalizations(Locale(languageCode));
  }

  String _localizedPrayerName(AppLocalizations l10n, PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return l10n.fajr;
      case PrayerType.sunrise:
        return l10n.sunrise;
      case PrayerType.dhuhr:
        return l10n.dhuhr;
      case PrayerType.asr:
        return l10n.asr;
      case PrayerType.maghrib:
        return l10n.maghrib;
      case PrayerType.isha:
        return l10n.isha;
      case PrayerType.midnight:
        return l10n.midnight;
      case PrayerType.lastThird:
        return l10n.lastThird;
    }
  }

  String _dateKey(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Deterministic fingerprint of the inputs that affect alarm timing. A
  /// matching fingerprint on the same calendar day is treated as "already
  /// scheduled" — different fingerprint ⇒ schedule changed and we reschedule.
  String _computeFingerprint({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
  }) {
    final Map<String, dynamic> json = settings.toJson();
    final double lat = (prayerTimesForDays.first.latitude ?? 0).toDouble();
    final double lon = (prayerTimesForDays.first.longitude ?? 0).toDouble();
    final String fingerprint = [
      jsonEncode(json),
      lat.toStringAsFixed(4),
      lon.toStringAsFixed(4),
      settings.calculationMethod.name,
    ].join('|');
    return fingerprint;
  }
}
