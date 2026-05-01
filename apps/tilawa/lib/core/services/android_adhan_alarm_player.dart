import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import '../logging/app_logger.dart';

/// Android implementation of [IAdhanAlarmPlayer] backed by the native
/// `AlarmManager.setAlarmClock` + `AdhanPlaybackService` pipeline.
///
/// Calls cross the [_channel] method channel into [MainActivity] which
/// delegates to `AdhanScheduler`. Playback survives app termination and
/// device reboot (the boot receiver re-installs persisted entries).
///
/// Registered both as itself (for callers that need the boot-receiver and
/// battery-optimisation extension methods) and as [IAdhanAlarmPlayer] for
/// the domain `PrayerAdhanNotificationService`.
@lazySingleton
class AndroidAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  AndroidAdhanAlarmPlayer();

  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/prayer_adhan',
  );

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
  }) async {
    if (!isSupported) return false;
    try {
      final bool ok =
          await _channel.invokeMethod<bool>('scheduleAdhan', {
            'id': id,
            'prayerName': prayerName,
            'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
          }) ??
          false;
      if (!ok) {
        logger.w(
          '[AndroidAdhanAlarmPlayer] scheduleAdhan returned false for $prayerName id=$id '
          '(likely missing exact-alarm permission)',
        );
      }
      return ok;
    } on PlatformException catch (e) {
      logger.e('[AndroidAdhanAlarmPlayer] scheduleAdhan failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> cancelAdhan(int id) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelAdhan', {'id': id});
    } on PlatformException catch (e) {
      logger.e('[AndroidAdhanAlarmPlayer] cancelAdhan failed: ${e.message}');
    }
  }

  @override
  Future<void> cancelAllAdhans() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelAllAdhans');
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] cancelAllAdhans failed: ${e.message}',
      );
    }
  }

  /// Persists the next-window alarm tuples so the native [PrayerBootReceiver]
  /// can re-install them after reboot without bringing up Flutter.
  @override
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('persistPendingAlarms', {
        'alarms': alarms
            .map(
              (a) => {
                'id': a.id,
                'name': a.prayerName,
                'triggerAtMillis': a.triggerAt.millisecondsSinceEpoch,
              },
            )
            .toList(),
      });
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] persistPendingAlarms failed: ${e.message}',
      );
    }
  }

  Future<void> clearPendingAlarms() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('clearPendingAlarms');
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] clearPendingAlarms failed: ${e.message}',
      );
    }
  }

  /// Returns true once per boot if the [PrayerBootReceiver] flagged that a
  /// fresh Dart-side reschedule should run. The flag is consumed atomically.
  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'consumeNeedsRescheduleAfterBoot',
          ) ??
          false;
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] consumeNeedsRescheduleAfterBoot failed: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return true;
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] isIgnoringBatteryOptimizations failed: ${e.message}',
      );
      return false;
    }
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] requestIgnoreBatteryOptimizations failed: ${e.message}',
      );
    }
  }

  @override
  Future<String?> manufacturer() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('manufacturer');
    } on PlatformException {
      return null;
    }
  }
}
