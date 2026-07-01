import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';

void main() {
  tearDown(SentryUserFeedback.resetForTesting);

  group('SentryUserFeedback.shouldPromptFeedbackForEvent', () {
    test('prompts only for release fatal events on physical devices', () {
      final SentryEvent eligible = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent verifyEvent = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.sentryVerify: 'true',
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent recoverableError = SentryEvent(
        level: SentryLevel.error,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'physical',
        },
      );

      final SentryEvent emulatorFatal = SentryEvent(
        level: SentryLevel.fatal,
        tags: <String, String>{
          CrashReportingTagKeys.deviceKind: 'emulator',
        },
      );

      if (kReleaseMode && !kIsWeb) {
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(eligible),
          isTrue,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(verifyEvent),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(recoverableError),
          isFalse,
        );
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(emulatorFatal),
          isFalse,
        );
      } else {
        expect(
          SentryUserFeedback.shouldPromptFeedbackForEvent(eligible),
          isFalse,
        );
      }
    });
  });
}
