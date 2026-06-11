import 'package:flutter/widgets.dart';

import 'core/bootstrap/app_error_guard.dart';
import 'core/bootstrap/app_startup.dart';
import 'features/prayer_times/application/prayer_notification_watchdog_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorGuard.install();
  await bootstrap();
}

@pragma('vm:entry-point')
Future<void> prayerNotificationWatchdogEntrypoint() async {
  await handlePrayerNotificationWatchdogEntrypoint();
}
