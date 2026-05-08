import 'core/bootstrap/app_startup.dart';
import 'features/prayer_times/presentation/prayer_notification_watchdog_entrypoint.dart';

Future<void> main() async {
  await bootstrap();
}

@pragma('vm:entry-point')
Future<void> prayerNotificationWatchdogEntrypoint() async {
  await handlePrayerNotificationWatchdogEntrypoint();
}
