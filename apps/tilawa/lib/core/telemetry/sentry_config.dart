import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'crash_reporting_context.dart';

/// Sentry client configuration for Tilawa.
///
/// Override at build time with `--dart-define=SENTRY_DSN=...` if needed.
abstract final class SentryConfig {
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://af9b4898a6280f738a01dd7e407982be@o4510837450211328.ingest.us.sentry.io/4511544533516288',
  );

  /// Applies Tilawa defaults to [options].
  ///
  /// Set [autoInitializeNativeSdk] to false on Android hot restart when the
  /// native SDK is still loaded from the previous Dart isolate.
  static void applyFlutterOptions(
    SentryFlutterOptions options, {
    required bool autoInitializeNativeSdk,
  }) {
    options.dsn = kProfileMode ? '' : SentryConfig.dsn;
    options.environment = kReleaseMode ? 'production' : 'development';
    options.debug = kDebugMode;
    options.enableLogs = kReleaseMode;
    options.enableMetrics = true;
    options.autoInitializeNativeSdk = autoInitializeNativeSdk;
    options.beforeSend = CrashReportingContext.filterBeforeSend;
    options.beforeSendLog = CrashReportingContext.filterBeforeSendLog;
  }
}
