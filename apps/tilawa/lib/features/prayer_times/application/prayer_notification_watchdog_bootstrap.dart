import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/features/prayer_times/application/prayer_watchdog_background_stubs.dart';
import 'package:tilawa/features/prayer_times/data/datasources/prayer_settings_datasource.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_notification_schedule_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/services/prayer_notification_permission_status_impl.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';

const MethodChannel _watchdogBackgroundChannel = MethodChannel(
  'com.tilawa.app/prayer_watchdog_background',
);

/// Minimal DI graph for the Android prayer notification watchdog isolate.
class PrayerNotificationWatchdogBootstrap {
  /// Builds the default background graph (used by the VM entrypoint).
  factory PrayerNotificationWatchdogBootstrap() {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final NotificationPermissionService permissionService =
        NotificationPermissionService(prefs);
    final AndroidAdhanAlarmPlayer adhanPlayer = AndroidAdhanAlarmPlayer();
    final prayerTimesRepository = PrayerTimesRepositoryImpl(
      PrayerSettingsDataSourceImpl(prefs),
      const PrayerWatchdogLocationDataSource(),
    );
    final notificationService = PrayerAdhanNotificationService(
      prefs,
      NotificationDispatcher(),
      const PrayerWatchdogNavigationService(),
      const PrayerWatchdogAnalyticsService(),
      adhanPlayer,
      permissionService,
    );
    final ensureScheduled = EnsurePrayerNotificationsScheduledUseCase(
      PrayerNotificationScheduleRepositoryImpl(prefs),
      PrayerNotificationPermissionStatusImpl(permissionService),
      prayerTimesRepository,
      SchedulePrayerNotificationsUseCase(
        notificationService,
        prayerTimesRepository,
      ),
      adhanPlayer,
    );
    return PrayerNotificationWatchdogBootstrap._(
      adhanPlayer: adhanPlayer,
      ensureScheduled: ensureScheduled,
    );
  }
  PrayerNotificationWatchdogBootstrap._({
    required this._adhanPlayer,
    required this._ensureScheduled,
  });

  final AndroidAdhanAlarmPlayer _adhanPlayer;
  final EnsurePrayerNotificationsScheduledUseCase _ensureScheduled;

  /// Runs ensure-scheduled logic and reports completion to native code.
  Future<void> run({MethodChannel? completionChannel}) async {
    final MethodChannel channel =
        completionChannel ?? _watchdogBackgroundChannel;

    bool success = true;
    bool retryable = false;
    String message = 'ok';
    String action = 'unknown';

    try {
      logger.d('[PrayerWatchdog] Background bootstrap started');

      bool forceReschedule = false;
      try {
        forceReschedule = await _adhanPlayer.consumeNeedsRescheduleAfterBoot();
      } catch (e) {
        logger.w('[PrayerWatchdog] Boot/timezone force flag probe failed: $e');
      }

      final result = await _ensureScheduled(forceReschedule: forceReschedule);
      await result.fold(
        (failure) async {
          success = false;
          retryable = true;
          message = failure.message ?? failure.toString();
          logger.w('[PrayerWatchdog] Ensure scheduled failed: $message');
        },
        (ensureResult) async {
          action = ensureResult.action.name;
          logger.d(
            '[PrayerWatchdog] Completed with action=$action '
            'remaining=${ensureResult.remainingWindow} '
            'until=${ensureResult.scheduledUntil}',
          );
        },
      );
    } catch (e, stackTrace) {
      success = false;
      retryable = true;
      message = e.toString();
      logger.e(
        '[PrayerWatchdog] Background bootstrap failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      try {
        await channel.invokeMethod<void>('watchdogComplete', {
          'success': success,
          'retryable': retryable,
          'message': message,
          'action': action,
        });
      } catch (e) {
        logger.e('[PrayerWatchdog] Failed to report completion: $e');
      }
    }
  }
}

/// Entry invoked from the VM background isolate ([main.dart]).
Future<void> handlePrayerNotificationWatchdogEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await PrayerNotificationWatchdogBootstrap().run();
}
