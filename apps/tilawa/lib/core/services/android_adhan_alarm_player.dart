import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  AndroidAdhanAlarmPlayer({
    @visibleForTesting @ignoreParam this._isSupportedOverride,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationTapped') {
        final args = call.arguments;
        final payload = args is Map ? args['payload'] as String? : null;
        if (payload != null) {
          if (_onNotificationTappedController.hasListener) {
            _emitNotificationTap(payload);
            unawaited(_ackNotificationTap(payload));
          } else {
            logger.d(
              '[AndroidAdhanAlarmPlayer] METHOD_CHANNEL_TAP_BUFFERED reason=no_flutter_listener',
            );
          }
        }
      }
    });
  }

  late final _onNotificationTappedController =
      StreamController<String>.broadcast(
        onListen: _drainPendingNotificationTap,
      );
  @override
  Stream<String> get onNotificationTapped =>
      _onNotificationTappedController.stream;

  @override
  Future<void> flushPendingNotificationTap() => _drainPendingNotificationTap();

  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/prayer_adhan',
  );

  final bool? _isSupportedOverride;

  @override
  bool get isSupported => _isSupportedOverride ?? Platform.isAndroid;

  void _emitNotificationTap(String payload) {
    logger.d('[AndroidAdhanAlarmPlayer] METHOD_CHANNEL_TAP_RECEIVED');
    _onNotificationTappedController.add(payload);
  }

  @override
  Future<String?> pullPendingNotificationTapPayload() async {
    if (!isSupported) return null;
    try {
      final pending = await _channel.invokeMethod<Object?>(
        'consumePendingNotificationTap',
      );
      if (pending is! Map) return null;
      return pending['payload'] as String?;
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] consumePendingNotificationTap failed: ${e.message}',
      );
      return null;
    }
  }

  Future<void> _drainPendingNotificationTap() async {
    final payload = await pullPendingNotificationTapPayload();
    if (payload == null) return;
    logger.d('[AndroidAdhanAlarmPlayer] METHOD_CHANNEL_TAP_FLUSHED');
    _emitNotificationTap(payload);
  }

  Future<void> _ackNotificationTap(String payload) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('ackNotificationTap', {
        'payload': payload,
      });
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] ackNotificationTap failed: ${e.message}',
      );
    }
  }

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
  }) async {
    if (!isSupported) return false;
    try {
      final bool ok =
          await _channel.invokeMethod<bool>('scheduleAdhan', {
            'id': id,
            'prayerName': prayerName,
            'prayerKey': prayerKey,
            'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
            'sound': sound,
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
  Future<void> cancelAdhan(int id, {String? prayerName}) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelAdhan', {
        'id': id,
        'prayerName': prayerName,
      });
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
                'key': a.prayerKey,
                'triggerAtMillis': a.triggerAt.millisecondsSinceEpoch,
                'sound': a.sound,
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
  Future<void> markNeedsReschedule() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('markNeedsReschedule');
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] markNeedsReschedule failed: ${e.message}',
      );
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

  @override
  Future<void> stopCurrentAdhan() async {
    if (!isSupported) return;
    try {
      logger.d('[AndroidAdhanAlarmPlayer] STOP_ADHAN_FROM_APP_REQUESTED');
      await _channel.invokeMethod<void>('stopAdhan');
      logger.d('[AndroidAdhanAlarmPlayer] STOP_ADHAN_FROM_APP_NATIVE_SUCCESS');
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] STOP_ADHAN_FROM_APP_NATIVE_FAILED: ${e.message}',
      );
    }
  }

  @override
  Future<bool> isAdhanPlaying() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAdhanPlaying') ?? false;
    } on PlatformException catch (e) {
      logger.e('[AndroidAdhanAlarmPlayer] isAdhanPlaying failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<String?> getActiveAdhanPayload() async {
    if (!isSupported) return null;
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'getActiveAdhanPayload',
      );
      if (raw == null) return null;
      if (raw is! Map) return null;
      final Map<String, dynamic> normalized = <String, dynamic>{
        for (final entry in raw.entries) entry.key.toString(): entry.value,
      };
      return jsonEncode(normalized);
    } on PlatformException catch (e) {
      logger.e(
        '[AndroidAdhanAlarmPlayer] getActiveAdhanPayload failed: ${e.message}',
      );
      return null;
    }
  }
}
