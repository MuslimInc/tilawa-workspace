import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/bootstrap/app_error_guard.dart';
import 'core/bootstrap/app_startup.dart';
import 'core/telemetry/crash_reporting_context.dart';
import 'core/telemetry/sentry_android_context.dart';
import 'core/telemetry/sentry_config.dart';
import 'features/prayer_times/application/prayer_notification_watchdog_bootstrap.dart';

Future<void> main() async {
  // Required before any plugin (PackageInfo, device_info, MethodChannel) runs.
  WidgetsFlutterBinding.ensureInitialized();

  // Install before Sentry so its integrations chain on top of the guard
  // instead of being replaced by it.
  AppErrorGuard.install();

  // Hot restart clears Sentry's Android applicationContext before main()
  // re-runs; restore it before native JNI init.
  await SentryAndroidContext.ensurePluginContext();

  await SentryFlutter.init(
    (SentryFlutterOptions options) {
      // Profile builds stay off; debug needs the DSN for Settings → Verify Sentry.
      options.dsn = kProfileMode ? '' : SentryConfig.dsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.debug = kDebugMode;
      options.enableLogs = !kProfileMode;
      options.beforeSend = CrashReportingContext.filterEmulatorsInRelease;
      options.beforeSendLog = CrashReportingContext.filterEmulatorLogsInRelease;
    },
    appRunner: () async {
      await CrashReportingContext.applyToSentry();
      await bootstrap();
    },
  );
}

@pragma('vm:entry-point')
Future<void> prayerNotificationWatchdogEntrypoint() async {
  await handlePrayerNotificationWatchdogEntrypoint();
}
