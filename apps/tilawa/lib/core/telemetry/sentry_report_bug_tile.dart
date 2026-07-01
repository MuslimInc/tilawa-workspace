import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/telemetry/sentry_user_feedback.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Settings entry that opens the Sentry user feedback form on demand.
class SentryReportBugTile extends StatelessWidget {
  const SentryReportBugTile({super.key, this.showDivider = true});

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (!Sentry.isEnabled) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return TilawaSettingsTile(
      title: l10n.reportBugSettingsTileTitle,
      showDivider: showDivider,
      onTap: () => SentryUserFeedback.showManualReportBugForm(),
    );
  }
}
