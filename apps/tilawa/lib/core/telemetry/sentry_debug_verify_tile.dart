import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer-only control that sends an intentional error to Sentry.
class SentryDebugVerifyTile extends StatelessWidget {
  const SentryDebugVerifyTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      icon: FluentIcons.bug_24_regular,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sentry is not initialized. Do a full restart (not hot restart).',
          ),
        ),
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

    if (!context.mounted) {
      return;
    }

    final String message;
    if (eventId == SentryId.empty()) {
      message =
          'Event was dropped or failed to send. '
          'Check logcat for [sentry] and filter Issues by '
          'environment: development.';
    } else {
      message =
          'Sent to Sentry ($eventId). '
          'In Issues, set environment to development and search '
          'sentry.verify:true.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
