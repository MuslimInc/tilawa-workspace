import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'core/bootstrap/app_startup.dart';
import 'features/prayer_times/application/prayer_notification_watchdog_bootstrap.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      details.exceptionAsString(),
      name: '[WidgetError]',
      error: details.exception,
      stackTrace: details.stack,
    );

    // Optional: keep default Flutter red screen behavior
    FlutterError.presentError(details);
  };
  await bootstrap();
}

@pragma('vm:entry-point')
Future<void> prayerNotificationWatchdogEntrypoint() async {
  await handlePrayerNotificationWatchdogEntrypoint();
}
