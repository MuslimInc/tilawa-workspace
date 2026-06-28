import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Server requires a non-empty reason; tutor UI does not collect one.
const tutorCancelSessionReason = 'tutor_cancelled';

/// Confirmation dialog for a teacher cancelling an accepted session.
Future<bool> showTutorCancelSessionDialog(BuildContext context) async {
  final l10n = context.quranSessionsL10n;
  final confirmed = await showTilawaConfirmDialog(
    context: context,
    title: l10n.tutorCancelSessionDialogTitle,
    message: l10n.tutorCancelSessionDialogMessage,
    confirmLabel: l10n.tutorCancelSessionAction,
    cancelLabel: l10n.tutorCancelSessionGoBack,
  );
  return confirmed == true;
}
