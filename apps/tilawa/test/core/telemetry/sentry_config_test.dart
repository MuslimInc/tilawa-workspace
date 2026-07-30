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
      // ignore: experimental_member_use
      expect(options.enableStandaloneAppStartTracing, isTrue);
      // Disabled: Sentry Flutter TTFD can assert '!duration.isNegative'.
      expect(options.enableTimeToFullDisplayTracing, isFalse);
      // ignore: experimental_member_use
      expect(options.profilesSampleRate, kReleaseMode ? 0.1 : 1.0);
      expect(options.autoInitializeNativeSdk, isFalse);
      // Debug Dart VM debugger pauses otherwise report as iOS app hangs.
      expect(options.enableAppHangTracking, kReleaseMode);
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
      expect(options.replay.onErrorSampleRate, 0.0);
      expect(options.replay.sessionSampleRate, 0.0);
      expect(options.privacy.maskAllText, isTrue);
      expect(options.privacy.maskAllImages, isTrue);
      final maskingRules =
          options.privacy.toJson()['maskingRules'] as List<dynamic>;
      expect(maskingRules, contains('ShrinkWrapInputShell: mask'));
      expect(
        maskingRules,
        contains(
          'AgoraCallVideoPlaceholder: Quran Sessions video-call placeholder.',
        ),
      );
      expect(
        maskingRules,
        contains(
          'AgoraVideoView: Agora RTC camera/participant video renderer.',
        ),
      );
      expect(
        maskingRules,
        contains(
          'PrivateRtcVideoLayouts: '
          'Mask private Quran Sessions video layout shells in replays.',
        ),
      );
      expect(
        maskingRules,
        contains(
          'SessionCallShellControls: '
          'Unmask call-shell controls falsely matched by the camera regex.',
        ),
      );
    });

    test('wrapRootWidget wraps child in SentryWidget', () {
      final Widget child = SentryConfig.wrapRootWidget(const Text('root'));

      expect(child, isA<SentryWidget>());
    });

    test('runWithExtendedAppStart runs action and always finishes', () async {
      var ran = false;
      final int result = await SentryConfig.runWithExtendedAppStart(() async {
        ran = true;
        return 42;
      });

      expect(ran, isTrue);
      expect(result, 42);
    });

    test('runWithExtendedAppStart finishes when action throws', () async {
      await expectLater(
        SentryConfig.runWithExtendedAppStart(() async {
          throw StateError('bootstrap failed');
        }),
        throwsA(isA<StateError>()),
      );
    });
  });
}
