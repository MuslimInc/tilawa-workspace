import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/bootstrap/app_error_guard.dart';
import 'core/bootstrap/app_environment.dart';
import 'core/bootstrap/app_startup.dart';
import 'core/telemetry/crash_reporting_context.dart';
import 'core/telemetry/sentry_android_context.dart';
import 'core/telemetry/sentry_config.dart';
import 'features/prayer_times/application/prayer_notification_watchdog_bootstrap.dart';

Future<void> _runTilawaApp() async {
  await CrashReportingContext.applyToSentry();
  await bootstrap();
}

Future<void> main() async {
  // Required before any plugin (PackageInfo, device_info, MethodChannel) runs.
  WidgetsFlutterBinding.ensureInitialized();

  AppEnvironment.assertProductionSafety();

  // Install before Sentry so its integrations chain on top of the guard
  // instead of being replaced by it.
  AppErrorGuard.install();

  // Hot restart clears Sentry's Android applicationContext before main()
  // re-runs; restore it before native JNI init.
  await SentryAndroidContext.ensurePluginContext();
  final bool skipNativeSentryInit =
      await SentryAndroidContext.isNativeSdkInitialized();

  await SentryFlutter.init(
    (SentryFlutterOptions options) {
      SentryConfig.applyFlutterOptions(
        options,
        autoInitializeNativeSdk: !skipNativeSentryInit,
      );
    },
    appRunner: _runTilawaApp,
  );
}

@pragma('vm:entry-point')
Future<void> prayerNotificationWatchdogEntrypoint() async {
  await handlePrayerNotificationWatchdogEntrypoint();
}
