import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/sentry_log_output.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer-only control that sends a test issue and structured log to Sentry.
class SentryDebugVerifyTile extends StatelessWidget {
  const SentryDebugVerifyTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      title: 'Verify Sentry setup',
      showDivider: !isLast,
      onTap: () => _sendTestEvent(context),
    );
  }

  Future<void> _sendTestEvent(BuildContext context) async {
    if (!Sentry.isEnabled) {
      if (!context.mounted) {
        return;
      }
      TilawaFeedback.showToast(
        context,
        message:
            'Sentry is not initialized. Do a full restart (not hot restart).',
        variant: TilawaFeedbackVariant.warning,
      );
      return;
    }

    // Unique message so a previously ignored/deleted verify issue does not
    // cause Sentry to discard future events server-side.
    final String verifyId = DateTime.now().toUtc().toIso8601String();
    final SentryId eventId = await Sentry.captureException(
      StateError('Sentry verify test ($verifyId)'),
      stackTrace: StackTrace.current,
      withScope: (Scope scope) {
        scope.setTag(CrashReportingTagKeys.sentryVerify, 'true');
        scope.fingerprint = <String>['sentry-verify', verifyId];
      },
    );

    if (SentryLogOutput.forwardingEnabled) {
      Sentry.logger.warn(
        'Sentry verify log ($verifyId)',
        attributes: <String, SentryAttribute>{
          CrashReportingTagKeys.sentryVerify: SentryAttribute.string('true'),
        },
      );
    }

    if (!context.mounted) {
      return;
    }

    final String message;
    if (eventId == SentryId.empty()) {
      message =
          'Issue was dropped or failed to send. '
          'Check logcat for [sentry]. Filter Issues by sentry.verify:true.';
    } else {
      message =
          'Sent verify issue ($eventId). '
          'Structured logs are production-only; filter Issues by sentry.verify:true.';
    }

    TilawaFeedback.showToast(
      context,
      message: message,
      variant: eventId == SentryId.empty()
          ? TilawaFeedbackVariant.warning
          : TilawaFeedbackVariant.success,
    );
  }
}
