import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/features/quran_sessions/presentation/teacher_application_analytics.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Opens the teacher application bottom sheet (Google Form intake).
Future<void> showTeacherApplicationEntrySheet(BuildContext context) {
  final l10n = context.l10n;
  logTeacherApplicationEntrySeen();

  return showTilawaFormSheet<void>(
    context: context,
    title: l10n.teacherApplicationSheetTitle,
    bodyBuilder: (sheetContext) {
      return Text(
        l10n.teacherApplicationSheetBody,
        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
        ),
      );
    },
    primaryLabel: l10n.teacherApplicationOpenFormCta,
    onPrimary: () {
      logTeacherApplicationEntryTapped();
      Navigator.of(context).pop();
      openTeacherApplicationForm(context);
    },
    secondaryLabel: l10n.teacherApplicationLaterCta,
    onSecondary: () => Navigator.of(context).pop(),
    sheetSemanticsLabel: l10n.teacherApplicationSheetTitle,
  );
}

/// Opens the configured Google Form in the external browser.
Future<void> openTeacherApplicationForm(BuildContext context) async {
  final formUrl = quranSessionsFeatureConfig().teacherApplicationFormUrl;
  if (formUrl.isEmpty) {
    logTeacherApplicationFormFailed();
    if (context.mounted) {
      TilawaFeedback.showToast(
        context,
        message: context.l10n.teacherApplicationFormOpenFailed,
        variant: TilawaFeedbackVariant.error,
      );
    }
    return;
  }

  final opened = await openLegalUrl(formUrl);
  if (opened) {
    logTeacherApplicationFormOpened();
    return;
  }

  logTeacherApplicationFormFailed();
  if (context.mounted) {
    TilawaFeedback.showToast(
      context,
      message: context.l10n.teacherApplicationFormOpenFailed,
      variant: TilawaFeedbackVariant.error,
    );
  }
}
