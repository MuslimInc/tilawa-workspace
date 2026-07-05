import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/telemetry/sentry_log_output.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
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
import '../../features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import '../config/notification_config.dart';
import 'notification_permission_service.dart';
import 'prayer_notification_config.dart';
import 'prayer_notification_payload_classifier.dart';

/// Prayer time entries that participate in scheduled notifications. Sunrise is
/// notification-only; midnight and lastThird are not user-configurable.
const List<PrayerType> _schedulablePrayers = [
  PrayerType.fajr,
  PrayerType.sunrise,
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
    this._notificationPermissionService, {
    @ignoreParam @visibleForTesting this._isAndroidOverride,
  });

  final SharedPreferencesAsync _prefs;
  final INotificationDispatcher _dispatcher;
  final NavigationService _navigationService;
  final AnalyticsService _analytics;
  final IAdhanAlarmPlayer _adhanPlayer;
  final NotificationPermissionService _notificationPermissionService;
  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

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
      await _flushPendingTapBestEffort();
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
          logger.w(
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
        matcher: isPrayerPayload,
        handler: handleNotificationResponse,
      );

      // Handle native notification taps (from AdhanPlaybackService)
      _adhanPlayer.onNotificationTapped.listen((payload) {
        logger.d(
          '${PrayerNotificationConfig.logTag} FLUTTER_TAP_PAYLOAD_RECEIVED source=native_method_channel',
        );
        handleNotificationResponse(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: payload,
          ),
        );
      });
      await _flushPendingTapBestEffort();

      if (_isAndroid) {
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

    // Adhan channels: config changes ship under a NEW channel ID because
    // Android resurrects deleted channels (with their old settings) when the
    // same ID is recreated. On upgrade we only delete the retired IDs so they
    // vanish from the system settings UI.
    final int? installedVersion = await _prefs.getInt(
      PrayerNotificationConfig.adhanChannelVersionKey,
    );
    if (installedVersion != PrayerNotificationConfig.adhanChannelVersion) {
      for (final String legacyChannelId
          in PrayerNotificationConfig.legacyAdhanChannelIds) {
        await androidPlugin.deleteNotificationChannel(
          channelId: legacyChannelId,
        );
      }
      logger.d(
        '${PrayerNotificationConfig.logTag} Adhan channels upgraded to v${PrayerNotificationConfig.adhanChannelVersion}',
      );
    }
    // Both adhan channels must not vibrate: the notification is posted at the
    // exact moment adhan audio starts, and the vibration motor is audible over
    // the opening of the recording.
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
        enableVibration: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        PrayerNotificationConfig.silentAdhanChannelId,
        l10n.prayerNotificationsSilentAdhanChannelName,
        description: l10n.prayerNotificationsSilentAdhanChannelDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
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
        await cancelAllPrayerNotifications();
        await _clearDedupState();
        await _analytics.logEvent(
          'permission_revoked_cleanup_completed',
          parameters: <String, Object>{
            'reason': 'notification_permission_denied',
          },
        );
        logger.w(
          '${PrayerNotificationConfig.logTag} Notification permission denied — scheduling suppressed and existing cancelled',
        );
        return;
      }

      // Dedup
      final String today = _todayDateKey();
      final String languageCode = await _currentLanguageCode();
      final String currentFingerprint = _computeFingerprint(
        settings: settings,
        prayerTimesForDays: prayerTimesForDays,
        languageCode: languageCode,
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
      final String? notificationLocationLabel =
          _resolveNotificationLocationLabel(
            l10n,
            settings,
            prayerTimesForDays,
          );
      final int dayCount =
          prayerTimesForDays.length < PrayerNotificationConfig.scheduleDaysAhead
          ? prayerTimesForDays.length
          : PrayerNotificationConfig.scheduleDaysAhead;
      int scheduled = 0;
      DateTime? earliestScheduledTarget;
      DateTime? latestScheduledTarget;
      final List<PendingAdhanAlarm> pendingAdhans = <PendingAdhanAlarm>[];
      bool loggedAdhanFallbackThisPass = false;
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
          final bool useAdhan = prayerSettings.playAdhan;
          String effectiveSound = prayerSettings.adhanSound;
          if (prayer == PrayerType.fajr &&
              effectiveSound.startsWith('adhan_')) {
            effectiveSound = '${effectiveSound}_fajr';
          }
          final String payload = jsonEncode({
            PrayerNotificationConfig.payloadTypeKey:
                PrayerNotificationConfig.payloadTypeValue,
            PrayerNotificationConfig.payloadPrayerKey: prayer.name,
            'prayer_name': prayer.name,
            'prayer_key': prayer.name.toLowerCase(),
            PrayerNotificationConfig.payloadDateKey: _dateKey(dayTimes.date),
            'scheduled_time_ms': targetTime.millisecondsSinceEpoch,
            'adhan_enabled': useAdhan,
            'notification_id': notificationId,
          });

          logger.d(
            '${PrayerNotificationConfig.logTag} [SCHEDULE] ${prayer.name} '
            'day+$dayOffset id=$notificationId at $tzTarget | '
            'channel=${useAdhan ? PrayerNotificationConfig.adhanChannelId : PrayerNotificationConfig.channelId} | adhan=$useAdhan | '
            'mode=${canScheduleExact ? 'exact' : 'inexact'}',
          );
          bool adhanHandledNatively = false;
          logger.d(
            '${PrayerNotificationConfig.logTag} [ADHAN CHECK] ${prayer.name} '
            'playAdhan=$useAdhan | adhanPlayer.isSupported=${_adhanPlayer.isSupported}',
          );
          if (useAdhan && _adhanPlayer.isSupported) {
            try {
              adhanHandledNatively = await _adhanPlayer.scheduleAdhan(
                id: notificationId,
                scheduledTime: targetTime,
                prayerName: prayer.name,
                prayerKey: prayer.name.toLowerCase(),
                sound: effectiveSound,
                locationName: notificationLocationLabel,
                languageCode: languageCode,
              );
              if (adhanHandledNatively) {
                logger.d(
                  '${PrayerNotificationConfig.logTag} ADHAN_AUDIT source=flutter_fallback '
                  'event=skip_fallback_native_success prayerKey=${prayer.name.toLowerCase()} '
                  'prayerName=${prayer.name} scheduledMs=${targetTime.millisecondsSinceEpoch} '
                  'notificationId=$notificationId channelId=${PrayerNotificationConfig.adhanChannelId}',
                );
                pendingAdhans.add(
                  PendingAdhanAlarm(
                    id: notificationId,
                    prayerName: prayer.name,
                    prayerKey: prayer.name.toLowerCase(),
                    triggerAt: targetTime,
                    sound: effectiveSound,
                    locationName: notificationLocationLabel,
                    languageCode: languageCode,
                  ),
                );
                logger.d(
                  '${PrayerNotificationConfig.logTag} [ADHAN SCHEDULED] ${prayer.name} via adhanPlayer',
                );
              }
            } catch (e) {
              logger.e(
                '${PrayerNotificationConfig.logTag} [ADHAN FAIL] adhanPlayer.scheduleAdhan failed for ${prayer.name}: $e',
              );
            }
          }

          // XOR Routing Logic:
          // 1. We first attempt to schedule the Adhan via the Native player (Android only).
          // 2. If the native player succeeds (adhanHandledNatively == true), it will
          //    manage its own notification and playback in a foreground service.
          // 3. To avoid duplicate notifications, we SKIP the Flutter Local Notification (FLN).
          // 4. If native scheduling is disabled (user setting) or fails (fallback),
          //    we schedule a standard FLN notification.
          if (!adhanHandledNatively) {
            logger.d(
              '${PrayerNotificationConfig.logTag} ADHAN_AUDIT source=flutter_fallback '
              'event=schedule_fallback prayerKey=${prayer.name.toLowerCase()} '
              'prayerName=${prayer.name} scheduledMs=${targetTime.millisecondsSinceEpoch} '
              'notificationId=$notificationId channelId='
              '${useAdhan ? PrayerNotificationConfig.adhanChannelId : PrayerNotificationConfig.channelId}',
            );
            try {
              await _notifications.zonedSchedule(
                id: notificationId,
                title: _titleFor(
                  l10n,
                  prayer,
                  locationName: notificationLocationLabel,
                ),
                body: _bodyFor(
                  l10n,
                  prayer,
                  locationName: notificationLocationLabel,
                ),
                scheduledDate: tzTarget,
                notificationDetails: _detailsFor(
                  l10n,
                  useAdhan,
                  adhanHandledNatively: adhanHandledNatively,
                ),
                androidScheduleMode: scheduleMode,
                matchDateTimeComponents: null,
                payload: payload,
              );
              scheduled++;
              earliestScheduledTarget =
                  earliestScheduledTarget == null ||
                      targetTime.isBefore(earliestScheduledTarget)
                  ? targetTime
                  : earliestScheduledTarget;
              latestScheduledTarget =
                  latestScheduledTarget == null ||
                      targetTime.isAfter(latestScheduledTarget)
                  ? targetTime
                  : latestScheduledTarget;
              logger.d(
                '${PrayerNotificationConfig.logTag} [SCHEDULE OK] ${prayer.name} '
                '${_dateKey(dayTimes.date)} scheduled successfully '
                '(${canScheduleExact ? 'exact' : 'inexact'} | '
                'adhan=$useAdhan | native=$adhanHandledNatively)',
              );
            } catch (e) {
              logger.e(
                '${PrayerNotificationConfig.logTag} [SCHEDULE FAIL] ${prayer.name} '
                '${_dateKey(dayTimes.date)} id=$notificationId: $e',
              );
            }
          } else {
            // Native handled it, just update counters for logging
            scheduled++;
            earliestScheduledTarget =
                earliestScheduledTarget == null ||
                    targetTime.isBefore(earliestScheduledTarget)
                ? targetTime
                : earliestScheduledTarget;
            latestScheduledTarget =
                latestScheduledTarget == null ||
                    targetTime.isAfter(latestScheduledTarget)
                ? targetTime
                : latestScheduledTarget;
          }

          if (useAdhan && !adhanHandledNatively) {
            await _analytics.logEvent(
              'adhan_fallback_used',
              parameters: <String, Object>{
                'prayer_name': prayer.name,
                'notification_id': notificationId,
                'reason': _adhanPlayer.isSupported
                    ? 'native_schedule_failed'
                    : 'native_not_supported',
                'exact_alarm_permission_granted': canScheduleExact,
              },
            );
            if (!loggedAdhanFallbackThisPass) {
              loggedAdhanFallbackThisPass = true;
              logger.w(
                '${PrayerNotificationConfig.logTag} [ADHAN] adhanPlayer not supported or failed — '
                'relying on notification channel sound (${PrayerNotificationConfig.adhanSoundRawName})',
              );
            }
          } else if (!useAdhan) {
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
        await _persistScheduleSnapshot(
          scheduledCount: scheduled,
          windowStart: earliestScheduledTarget,
          windowEnd: latestScheduledTarget,
        );
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} Failed to persist schedule state: $e',
        );
      }

      // Persist the next-window adhan tuples so the platform boot receiver
      // can re-arm AlarmManager entries after a reboot without bringing up
      // a Dart isolate. Best-effort — failures here only weaken the post-
      // boot path; the next app launch's full reschedule still recovers.
      try {
        await _adhanPlayer.persistPendingAlarms(pendingAdhans);
      } catch (e) {
        logger.w(
          '${PrayerNotificationConfig.logTag} persistPendingAlarms failed: $e',
        );
      }

      logger.d(
        '${PrayerNotificationConfig.logTag} Scheduled $scheduled prayer notifications '
        '(${pendingAdhans.length} adhan alarms persisted for boot recovery)',
      );
      if (SentryLogOutput.forwardingEnabled) {
        Sentry.logger.info(
          '${PrayerNotificationConfig.logTag} Prayer notifications scheduled',
          attributes: <String, SentryAttribute>{
            'scheduled_count': SentryAttribute.int(scheduled),
            'pending_adhan_count': SentryAttribute.int(pendingAdhans.length),
            'exact_alarm': SentryAttribute.bool(canScheduleExact),
            'schedule_mode': SentryAttribute.string(
              canScheduleExact ? 'exact' : 'inexact',
            ),
          },
        );
      }
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
          await _adhanPlayer.cancelAdhan(
            PrayerNotificationConfig.dynamicId(dayOffset, prayer),
            prayerName: prayer.name,
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
      await _clearScheduleSnapshot();
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
    if (!_isAndroid) {
      return true;
    }
    try {
      final AndroidFlutterLocalNotificationsPlugin? impl = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final bool canExact = await impl?.canScheduleExactNotifications() ?? true;
      return canExact;
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
    if (!_isAndroid) {
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
        'prayer_name': prayer.name,
        'prayer_key': prayer.name.toLowerCase(),
        PrayerNotificationConfig.payloadDateKey: _todayDateKey(),
        'scheduled_time_ms': DateTime.now().millisecondsSinceEpoch,
        'adhan_enabled': playAdhan,
        'notification_id': testId,
      });
      final String channelUsed = playAdhan
          ? PrayerNotificationConfig.adhanChannelId
          : PrayerNotificationConfig.channelId;
      final String soundFile = playAdhan
          ? PrayerNotificationConfig.adhanSoundRawName
          : 'default';
      final AppLocalizations l10n = await _localizations();
      final String languageCode = await _currentLanguageCode();
      final String? notificationLocationLabel =
          await _locationLabelFromSavedSettings(l10n);

      bool adhanHandledNatively = false;
      if (playAdhan && _adhanPlayer.isSupported) {
        String effectiveSound = 'adhan_1'; // Default test sound
        if (prayer == PrayerType.fajr) {
          effectiveSound = 'adhan_1_fajr';
        }

        try {
          final DateTime trigger = DateTime.now().add(
            const Duration(seconds: 1),
          );
          adhanHandledNatively = await _adhanPlayer.scheduleAdhan(
            id: testId,
            scheduledTime: trigger,
            prayerName: prayer.name,
            prayerKey: prayer.name.toLowerCase(),
            sound: effectiveSound,
            locationName: notificationLocationLabel,
            languageCode: languageCode,
          );
        } catch (e) {
          logger.w(
            '${PrayerNotificationConfig.logTag} [TEST] Native adhan schedule failed: $e',
          );
        }
      }

      bool immediatePlayback = false;
      if (playAdhan && !adhanHandledNatively && _adhanPlayer.isSupported) {
        immediatePlayback = await _adhanPlayer.playAdhanNow(
          id: testId,
          prayerName: prayer.name,
          prayerKey: prayer.name.toLowerCase(),
          locationName: notificationLocationLabel,
          languageCode: languageCode,
        );
      }

      logger.d(
        '${PrayerNotificationConfig.logTag} [TEST] Firing test notification | '
        'prayer=${prayer.name} | playAdhan=$playAdhan | native=$adhanHandledNatively | '
        'immediate=$immediatePlayback | id=$testId',
      );
      // XOR: native alarm scheduled, immediate FG playback, or FLN card — never two.
      if (!adhanHandledNatively && !immediatePlayback) {
        await _notifications.show(
          id: testId,
          title: _titleFor(
            l10n,
            prayer,
            locationName: notificationLocationLabel,
          ),
          body: _bodyFor(l10n, prayer, locationName: notificationLocationLabel),
          notificationDetails: _detailsFor(
            l10n,
            playAdhan,
            adhanHandledNatively: false,
          ),
          payload: payload,
        );
        logger.d(
          '${PrayerNotificationConfig.logTag} [TEST OK] Notification delivered to system | '
          'prayer=${prayer.name} | channel=$channelUsed | sound=$soundFile',
        );
      } else {
        logger.d(
          '${PrayerNotificationConfig.logTag} [TEST OK] Native/immediate adhan; FLN suppressed | '
          'prayer=${prayer.name} | id=$testId',
        );
      }
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

  @override
  Future<void> debugScheduleTestAdhan() async {
    const String tag = '[AdhanManualTest]';
    try {
      final bool isIgnoringBattery = await _adhanPlayer
          .isIgnoringBatteryOptimizations();
      logger.i(
        '$tag Starting test schedule sequence (delay=10s) | batteryOptimizationsIgnored=$isIgnoringBattery',
      );

      final DateTime now = DateTime.now();
      final DateTime triggerAt = now.add(const Duration(seconds: 10));
      final int testId = PrayerNotificationConfig.debugManualTestId;

      final bool hasPermission = await _notificationPermissionService
          .isPermissionGranted();
      if (!hasPermission) {
        logger.w('$tag Permission missing: POST_NOTIFICATIONS');
        return;
      }

      final bool canExact = await canScheduleExactAlarms();
      if (!canExact) {
        logger.w('$tag Permission missing: USE_EXACT_ALARM');
      }

      bool nativeSuccess = false;
      if (_adhanPlayer.isSupported) {
        final String languageCode = await _currentLanguageCode();
        final AppLocalizations l10n = await _localizations();
        final String? notificationLocationLabel =
            await _locationLabelFromSavedSettings(l10n);
        nativeSuccess = await _adhanPlayer.scheduleAdhan(
          id: testId,
          scheduledTime: triggerAt,
          prayerName: 'DEBUG_ADHAN',
          prayerKey: 'debug',
          locationName: notificationLocationLabel,
          languageCode: languageCode,
        );
      }

      final AppLocalizations l10n = await _localizations();
      final tz.TZDateTime tzTarget = tz.TZDateTime.from(triggerAt, tz.local);

      final String channelId = nativeSuccess
          ? PrayerNotificationConfig.silentAdhanChannelId
          : PrayerNotificationConfig.adhanChannelId;

      logger.d(
        '$tag Scheduled test adhan:\n'
        '- scheduledAt: $now\n'
        '- triggerAt: $triggerAt\n'
        '- nativeScheduleSuccess: $nativeSuccess\n'
        '- selectedNotificationChannel: $channelId\n'
        '- FLN is: ${nativeSuccess ? 'silent' : 'audible'}\n'
        '- id: $testId',
      );

      if (!nativeSuccess) {
        await _notifications.zonedSchedule(
          id: testId,
          title: 'MeMuslim Debug',
          body: 'Manual Adhan Test (10s) - Fallback',
          scheduledDate: tzTarget,
          notificationDetails: _detailsFor(
            l10n,
            true, // playAdhan
            adhanHandledNatively: nativeSuccess,
          ),
          androidScheduleMode: canExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexact,
          payload: jsonEncode({
            PrayerNotificationConfig.payloadTypeKey:
                PrayerNotificationConfig.payloadTypeValue,
            PrayerNotificationConfig.payloadPrayerKey: 'debug',
            'prayer_name': 'DEBUG_ADHAN',
            'prayer_key': 'debug',
            'scheduled_time_ms': triggerAt.millisecondsSinceEpoch,
            'adhan_enabled': true,
            'notification_id': testId,
          }),
        );
      }
    } catch (e, st) {
      logger.e('$tag Failed: $e', error: e, stackTrace: st);
    }
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    try {
      final String? payload = response.payload;
      final NotificationPayloadKind payloadKind = classifyPayloadKind(payload);
      logger.d(
        '${PrayerNotificationConfig.logTag} FLUTTER_TAP_PAYLOAD_RECEIVED id=${response.id} kind=$payloadKind hasPayload=${payload != null}',
      );
      if (!isPrayerPayloadOwnedByPrayerService(payloadKind) ||
          payload == null) {
        return;
      }

      // Navigate to status screen with extras
      _navigateToPrayerStatus(payload);
      unawaited(_logNotificationTapAnalytics(payload, response.id));
    } catch (e, stackTrace) {
      logger.e(
        '${PrayerNotificationConfig.logTag} handleNotificationResponse failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _logNotificationTapAnalytics(
    String payload,
    int? notificationId,
  ) async {
    String? prayerName;

    try {
      final dynamic decoded = jsonDecode(payload);
      final Map<String, Object> params = <String, Object>{};

      if (decoded is Map<String, dynamic>) {
        final dynamic prayerKey =
            decoded[PrayerNotificationConfig.payloadPrayerKey];
        final dynamic fallbackPrayerName = decoded['prayer_name'];
        if (prayerKey is String) {
          prayerName = prayerKey;
        } else if (fallbackPrayerName is String) {
          prayerName = fallbackPrayerName;
        }

        final dynamic adhanEnabled = decoded['adhan_enabled'];
        if (adhanEnabled is bool) {
          params['adhan_enabled'] = adhanEnabled;
          params['is_adhan'] = adhanEnabled;
        }
      }

      if (prayerName != null) {
        params['prayer_name'] = prayerName;
        params['prayer_key'] = prayerName.toLowerCase();
      }
      if (notificationId != null) {
        params['notification_id'] = notificationId;
      }

      await _analytics.logEvent(
        'prayer_notification_tapped',
        parameters: params,
      );
    } catch (e) {
      logger.w('${PrayerNotificationConfig.logTag} Analytics log failed: $e');
    }
  }

  void _navigateToPrayerStatus(String payload) {
    try {
      final NotificationDestination destination = const DeepLinkResolver()
          .prayerStatus(payload);
      if (_shouldDeferPrayerStatusNavigation()) {
        AppRouter.setPendingColdStartRoute(
          destination.location,
          extra: destination.extra ?? payload,
        );
        logger.d(
          '${PrayerNotificationConfig.logTag} NAVIGATION_TO_PRAYER_STATUS_DEFERRED',
        );
        return;
      }
      logger.d(
        '${PrayerNotificationConfig.logTag} NAVIGATION_TO_PRAYER_STATUS_REQUESTED route=${destination.location}',
      );
      _navigationService.routeToDestination(destination);
      logger.d(
        '${PrayerNotificationConfig.logTag} NAVIGATION_TO_PRAYER_STATUS_SUCCESS',
      );
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} NAVIGATION_TO_PRAYER_STATUS_FAILED: $e',
      );
    }
  }

  bool _shouldDeferPrayerStatusNavigation() {
    if (AppRouter.pendingColdStartLocation != null) {
      return true;
    }
    if (AppRouter.pendingStartupNotificationLaunch) {
      return true;
    }
    final String? location = _navigationService.getCurrentLocation();
    if (location == const SplashRoute().location) {
      return true;
    }
    return false;
  }

  // -- helpers ----------------------------------------------------------------

  @visibleForTesting
  NotificationPayloadKind classifyPayloadKind(String? payload) {
    return classifyPrayerNotificationPayload(payload);
  }

  @visibleForTesting
  bool isPrayerPayload(String? payload) {
    return isPrayerPayloadOwnedByPrayerService(classifyPayloadKind(payload));
  }

  PrayerNotificationSettings _settingsFor(
    PrayerSettingsEntity settings,
    PrayerType prayer,
  ) {
    return switch (prayer) {
      PrayerType.fajr => settings.fajrNotification,
      PrayerType.sunrise => settings.sunriseNotification,
      PrayerType.dhuhr => settings.dhuhrNotification,
      PrayerType.asr => settings.asrNotification,
      PrayerType.maghrib => settings.maghribNotification,
      PrayerType.isha => settings.ishaNotification,
      PrayerType.midnight => const PrayerNotificationSettings(
        mode: PrayerAlertMode.none,
      ),
      PrayerType.lastThird => const PrayerNotificationSettings(
        mode: PrayerAlertMode.none,
      ),
    };
  }

  DateTime _prayerDateTime(PrayerTimeEntity day, PrayerType prayer) {
    return switch (prayer) {
      PrayerType.fajr => day.fajr,
      PrayerType.sunrise => day.sunrise,
      PrayerType.dhuhr => day.dhuhr,
      PrayerType.asr => day.asr,
      PrayerType.maghrib => day.maghrib,
      PrayerType.isha => day.isha,
      PrayerType.midnight => day.midnight,
      PrayerType.lastThird => day.lastThird,
    };
  }

  String _titleFor(
    AppLocalizations l10n,
    PrayerType prayer, {
    String? locationName,
  }) {
    final String prayerLabel = _localizedPrayerName(l10n, prayer);
    if (locationName == null || locationName.isEmpty) {
      return prayerLabel;
    }
    return l10n.prayerNotificationTitleWithLocation(prayerLabel, locationName);
  }

  String _bodyFor(
    AppLocalizations l10n,
    PrayerType prayer, {
    String? locationName,
  }) {
    final String prayerLabel = _localizedPrayerName(l10n, prayer);
    if (locationName == null || locationName.isEmpty) {
      return l10n.prayerNotificationBody(prayerLabel);
    }
    return l10n.prayerNotificationBodyWithLocation(
      prayerLabel,
      locationName,
    );
  }

  String? _resolveNotificationLocationLabel(
    AppLocalizations l10n,
    PrayerSettingsEntity settings,
    List<PrayerTimeEntity> prayerTimesForDays,
  ) {
    final String? fromSettings = _notificationLocationLabel(
      l10n,
      settings.effectiveSchedulingLocationName,
    );
    if (fromSettings != null) {
      return fromSettings;
    }

    if (prayerTimesForDays.isEmpty) {
      return null;
    }

    return _notificationLocationLabel(
      l10n,
      prayerTimesForDays.first.locationName,
    );
  }

  String? _notificationLocationLabel(
    AppLocalizations l10n,
    String? locationName,
  ) {
    if (locationName == null || locationName.trim().isEmpty) {
      return null;
    }
    final String label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
      locationName: locationName,
      l10n: l10n,
    );
    return label == l10n.unknownLocation ? null : label;
  }

  NotificationDetails _detailsFor(
    AppLocalizations l10n,
    bool playAdhan, {
    bool adhanHandledNatively = false,
  }) {
    final String channelId = playAdhan
        ? (adhanHandledNatively
              ? PrayerNotificationConfig.silentAdhanChannelId
              : PrayerNotificationConfig.adhanChannelId)
        : PrayerNotificationConfig.channelId;
    final String channelName = playAdhan
        ? (adhanHandledNatively
              ? l10n.prayerNotificationsSilentAdhanChannelName
              : l10n.prayerNotificationsAdhanChannelName)
        : l10n.prayerNotificationsChannelName;
    final String channelDescription = playAdhan
        ? (adhanHandledNatively
              ? l10n.prayerNotificationsSilentAdhanChannelDescription
              : l10n.prayerNotificationsAdhanChannelDescription)
        : l10n.prayerNotificationsChannelDescription;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: NotificationConfig.androidSmallIcon,
        color: AppColors.notificationAccent,
        sound: playAdhan && !adhanHandledNatively
            ? RawResourceAndroidNotificationSound(
                PrayerNotificationConfig.adhanSoundRawName,
              )
            : null,
        playSound: !playAdhan || !adhanHandledNatively,
        // Pre-O devices take vibration from the notification, not the
        // channel; adhan notifications must not buzz over the audio.
        enableVibration: !playAdhan,
        audioAttributesUsage: playAdhan && !adhanHandledNatively
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
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
      await _clearScheduleSnapshot();
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} Failed to clear dedup state: $e',
      );
    }
  }

  Future<void> _persistScheduleSnapshot({
    required int scheduledCount,
    required DateTime? windowStart,
    required DateTime? windowEnd,
  }) async {
    if (scheduledCount <= 0 || windowEnd == null) {
      await _clearScheduleSnapshot();
      return;
    }

    if (windowStart == null) {
      await _prefs.remove(PrayerNotificationConfig.scheduledWindowStartMsKey);
    } else {
      await _prefs.setInt(
        PrayerNotificationConfig.scheduledWindowStartMsKey,
        windowStart.millisecondsSinceEpoch,
      );
    }
    await _prefs.setInt(
      PrayerNotificationConfig.scheduledWindowEndMsKey,
      windowEnd.millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      PrayerNotificationConfig.scheduleCompletedAtMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      PrayerNotificationConfig.scheduledNotificationCountKey,
      scheduledCount,
    );
  }

  Future<void> _clearScheduleSnapshot() async {
    await _prefs.remove(PrayerNotificationConfig.scheduledWindowStartMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduledWindowEndMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduleCompletedAtMsKey);
    await _prefs.remove(PrayerNotificationConfig.scheduledNotificationCountKey);
  }

  Future<String?> _locationLabelFromSavedSettings(AppLocalizations l10n) async {
    try {
      final String? settingsJson = await _prefs.getString('prayer_settings');
      if (settingsJson == null) {
        return null;
      }
      final PrayerSettingsEntity settings = PrayerSettingsEntity.fromJson(
        jsonDecode(settingsJson) as Map<String, dynamic>,
      );
      return _notificationLocationLabel(
        l10n,
        settings.effectiveSchedulingLocationName,
      );
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} Failed to read saved location for test notification: $e',
      );
      return null;
    }
  }

  Future<AppLocalizations> _localizations() async {
    return lookupAppLocalizations(Locale(await _currentLanguageCode()));
  }

  Future<String> _currentLanguageCode() async {
    try {
      return await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;
    } catch (e) {
      logger.w(
        '${PrayerNotificationConfig.logTag} Failed to read locale preference: $e',
      );
      return LanguageConfig.defaultLanguageCode;
    }
  }

  String _localizedPrayerName(AppLocalizations l10n, PrayerType prayer) {
    return switch (prayer) {
      PrayerType.fajr => l10n.fajr,
      PrayerType.sunrise => l10n.sunrise,
      PrayerType.dhuhr => l10n.dhuhr,
      PrayerType.asr => l10n.asr,
      PrayerType.maghrib => l10n.maghrib,
      PrayerType.isha => l10n.isha,
      PrayerType.midnight => l10n.midnight,
      PrayerType.lastThird => l10n.lastThird,
    };
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
    required String languageCode,
  }) {
    final Map<String, dynamic> json = settings.toJson();
    final double lat = (prayerTimesForDays.first.latitude ?? 0).toDouble();
    final double lon = (prayerTimesForDays.first.longitude ?? 0).toDouble();
    final String fingerprint = [
      jsonEncode(json),
      lat.toStringAsFixed(4),
      lon.toStringAsFixed(4),
      settings.calculationMethod.name,
      languageCode,
      settings.effectiveSchedulingLocationName ?? '',
    ].join('|');
    return fingerprint;
  }

  Future<void> _flushPendingTapBestEffort() async {
    try {
      final dynamic result = (_adhanPlayer as dynamic)
          .flushPendingNotificationTap();
      if (result is Future<void>) {
        await result;
      } else if (result is Future) {
        await result;
      }
    } catch (_) {}
  }
}
