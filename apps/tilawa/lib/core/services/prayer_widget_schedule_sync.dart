import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/prayer_times/domain/entities/prayer_time_entity.dart';
import '../logging/app_logger.dart';

/// Pushes the multi-day prayer schedule to the native home-screen widget
/// (spec 041, P1) over the existing prayer method channel.
///
/// Kept separate from [IAdhanAlarmPlayer] on purpose: the widget is a display
/// surface, not part of the adhan playback contract, and a standalone class
/// avoids widening an interface that every test fake implements.
///
/// Best-effort by design — a failed push only leaves the widget on its
/// previous snapshot; the next schedule pass retries.
class PrayerWidgetScheduleSync {
  PrayerWidgetScheduleSync({
    @visibleForTesting MethodChannel? channel,
    @visibleForTesting this._isSupportedOverride,
  }) : _channel = channel ?? _defaultChannel;

  /// Same channel as [AndroidAdhanAlarmPlayer]; the native dispatcher routes
  /// by method name.
  static const MethodChannel _defaultChannel = MethodChannel(
    'com.tilawa.app/prayer_adhan',
  );

  /// Must match `PrayerWidgetSnapshot.SCHEMA_VERSION` on the Kotlin side.
  static const int schemaVersion = 1;

  final MethodChannel _channel;
  final bool? _isSupportedOverride;

  bool get isSupported =>
      _isSupportedOverride ?? (!kIsWeb && Platform.isAndroid);

  /// Serialises [days] and hands the snapshot to the native widget store.
  /// No-ops silently off-Android or when [days] is empty.
  Future<void> push({
    required List<PrayerTimeEntity> days,
    String? locationName,
  }) async {
    if (!isSupported || days.isEmpty) return;
    try {
      final String json = jsonEncode(<String, Object?>{
        'version': schemaVersion,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        'locationName': locationName ?? '',
        'days': <Map<String, Object?>>[
          for (final PrayerTimeEntity day in days)
            <String, Object?>{
              'fajr': day.fajr.millisecondsSinceEpoch,
              'sunrise': day.sunrise.millisecondsSinceEpoch,
              'dhuhr': day.dhuhr.millisecondsSinceEpoch,
              'asr': day.asr.millisecondsSinceEpoch,
              'maghrib': day.maghrib.millisecondsSinceEpoch,
              'isha': day.isha.millisecondsSinceEpoch,
            },
        ],
      });
      await _channel.invokeMethod<void>('updatePrayerWidgetSchedule', {
        'json': json,
      });
      logger.d(
        '[PrayerWidgetScheduleSync] Pushed ${days.length}-day snapshot to widget',
      );
    } on PlatformException catch (e) {
      logger.w('[PrayerWidgetScheduleSync] push failed: ${e.message}');
    } on MissingPluginException {
      // Native side not attached (e.g. tests, headless isolate) — safe to skip.
    }
  }
}
