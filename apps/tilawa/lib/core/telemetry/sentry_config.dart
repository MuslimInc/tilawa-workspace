import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../router/app_router.dart';
import '../bootstrap/app_environment.dart';
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
    options.environment = AppEnvironment.current.sentryEnvironment;
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
    // Shrink-wrap dropdown/input shells can show user-selected labels.
    // ignore: experimental_member_use
    options.privacy.mask<ShrinkWrapInputShell>();
    _configureSessionReplayVideoPrivacy(options.privacy);
  }

  /// Masks Quran Sessions RTC surfaces so live camera/participant video never
  /// appears in Session Replay captures (privacy requirement for video calls).
  static void _configureSessionReplayVideoPrivacy(
    SentryPrivacyOptions privacy,
  ) {
    // ignore: experimental_member_use
    privacy.mask<AgoraCallVideoPlaceholder>(
      description: 'Quran Sessions video-call placeholder.',
    );
    // Type-based rule survives Dart obfuscation in release builds.
    // ignore: experimental_member_use
    privacy.mask<AgoraVideoView>(
      description: 'Agora RTC camera/participant video renderer.',
    );
    // Private layout shells (_VideoLayout, _LiveKitVideoLayout) and
    // LiveKit [VideoTrackRenderer] are matched by runtime type name because
    // they are library-private; AgoraVideoView masking covers release video.
    // ignore: experimental_member_use
    privacy.maskCallback<Widget>(
      _replayPrivateVideoLayoutMaskDecision,
      name: 'PrivateRtcVideoLayouts',
      description:
          'Mask private Quran Sessions video layout shells in replays.',
    );
    // Flip-facing control is call chrome, not a camera feed; unmask silences
    // debug replay warnings for the library-private [_SwitchCameraButton].
    // ignore: experimental_member_use
    privacy.maskCallback<Widget>(
      _replayCallShellControlUnmaskDecision,
      name: 'SessionCallShellControls',
      description:
          'Unmask call-shell controls falsely matched by the camera regex.',
    );
  }

  // ignore: experimental_member_use
  static SentryMaskingDecision _replayPrivateVideoLayoutMaskDecision(
    Element element,
    Widget widget,
  ) {
    if (widget is InheritedWidget) {
      // ignore: experimental_member_use
      return SentryMaskingDecision.continueProcessing;
    }
    // ignore: experimental_member_use
    return switch (widget.runtimeType.toString()) {
      '_VideoLayout' ||
      '_LiveKitVideoLayout' ||
      // ignore: experimental_member_use
      'VideoTrackRenderer' => SentryMaskingDecision.mask,
      // ignore: experimental_member_use
      _ => SentryMaskingDecision.continueProcessing,
    };
  }

  // ignore: experimental_member_use
  static SentryMaskingDecision _replayCallShellControlUnmaskDecision(
    Element element,
    Widget widget,
  ) {
    if (widget is InheritedWidget) {
      // ignore: experimental_member_use
      return SentryMaskingDecision.continueProcessing;
    }
    // ignore: experimental_member_use
    return switch (widget.runtimeType.toString()) {
      '_SwitchCameraButton' =>
        // ignore: experimental_member_use
        SentryMaskingDecision.unmask,
      // ignore: experimental_member_use
      _ => SentryMaskingDecision.continueProcessing,
    };
  }

  /// Root [runApp] wrapper required for Session Replay widget capture.
  static Widget wrapRootWidget(Widget child) => SentryWidget(child: child);
}
