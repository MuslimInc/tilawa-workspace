import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/services/prayer_notification_watchdog_scheduler.dart';

@LazySingleton(as: PrayerNotificationWatchdogScheduler)
class MethodChannelPrayerNotificationWatchdogScheduler
    implements PrayerNotificationWatchdogScheduler {
  const MethodChannelPrayerNotificationWatchdogScheduler();

  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/prayer_watchdog',
  );

  @override
  Future<void> ensurePeriodicWatchdogScheduled() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('ensurePeriodicWatchdogScheduled');
    } on PlatformException catch (e) {
      logger.e(
        '[PrayerWatchdog] ensurePeriodicWatchdogScheduled failed: ${e.message}',
      );
    }
  }

  @override
  Future<void> runWatchdogNow() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('runPrayerNotificationWatchdogNow');
    } on PlatformException catch (e) {
      logger.e('[PrayerWatchdog] runWatchdogNow failed: ${e.message}');
    }
  }
}
