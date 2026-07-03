import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../router/app_router.dart';
import 'crash_reporting_context.dart';
import 'sentry_user_feedback.dart';

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
    options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
    options.enableTimeToFullDisplayTracing = true;
    // Relative to [tracesSampleRate]; 1.0 profiles all sampled transactions.
    // Alpha on iOS/macOS only (Sentry Flutter SDK >= 7.12.0).
    // ignore: experimental_member_use
    options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;
    options.autoInitializeNativeSdk = autoInitializeNativeSdk;
    SentryUserFeedback.bindFlutterOptions(options);
    options.navigatorKey = AppRouter.navigatorKey;
    options.attachScreenshot = true;
    options.beforeSend = SentryUserFeedback.filterBeforeSend;
    options.beforeSendLog = CrashReportingContext.filterBeforeSendLog;

    // Session Replay: always capture error replays; sample normal sessions in
    // production to limit volume. Traces sample rate matches replay cadence.
    options.replay.onErrorSampleRate = 1.0;
    options.replay.sessionSampleRate = kReleaseMode ? 0.1 : 1.0;

    // Defaults are true; set explicitly so privacy posture stays obvious in code.
    options.privacy.maskAllText = true;
    options.privacy.maskAllImages = true;
  }

  /// Root [runApp] wrapper required for Session Replay widget capture.
  static Widget wrapRootWidget(Widget child) => SentryWidget(child: child);
}
