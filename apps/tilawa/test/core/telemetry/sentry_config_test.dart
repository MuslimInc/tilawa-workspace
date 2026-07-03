import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_config.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa/router/app_router.dart';

void main() {
  tearDown(SentryUserFeedback.resetForTesting);

  group('SentryConfig', () {
    test('applyFlutterOptions wires Tilawa defaults', () {
      final SentryFlutterOptions options = SentryFlutterOptions();

      SentryConfig.applyFlutterOptions(
        options,
        autoInitializeNativeSdk: false,
      );

      expect(SentryUserFeedback.boundFlutterOptions, same(options));

      expect(options.dsn, kProfileMode ? '' : SentryConfig.dsn);
      expect(options.environment, kReleaseMode ? 'production' : 'development');
      expect(options.debug, kDebugMode);
      expect(options.enableLogs, kReleaseMode);
      expect(options.tracesSampleRate, kReleaseMode ? 0.1 : 1.0);
      expect(options.enableTimeToFullDisplayTracing, isTrue);
      // ignore: experimental_member_use
      expect(options.profilesSampleRate, kReleaseMode ? 0.1 : 1.0);
      expect(options.autoInitializeNativeSdk, isFalse);
      expect(options.navigatorKey, AppRouter.navigatorKey);
      expect(options.attachScreenshot, isTrue);
      expect(
        options.beforeSend,
        SentryUserFeedback.filterBeforeSend,
      );
      expect(
        options.beforeSendLog,
        CrashReportingContext.filterBeforeSendLog,
      );
      expect(options.replay.onErrorSampleRate, 1.0);
      expect(options.replay.sessionSampleRate, kReleaseMode ? 0.1 : 1.0);
      expect(options.privacy.maskAllText, isTrue);
      expect(options.privacy.maskAllImages, isTrue);
    });

    test('wrapRootWidget wraps child in SentryWidget', () {
      final Widget child = SentryConfig.wrapRootWidget(const Text('root'));

      expect(child, isA<SentryWidget>());
    });
  });
}
