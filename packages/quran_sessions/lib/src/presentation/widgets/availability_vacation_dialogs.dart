import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Asks the teacher to confirm removing a vacation / unavailable period.
Future<bool> showDeleteVacationConfirmDialog(BuildContext context) async {
  final l10n = context.quranSessionsL10n;
  final confirmed = await showTilawaConfirmDialog(
    context: context,
    title: l10n.availabilityDeleteVacationTitle,
    message: l10n.availabilityDeleteVacationMessage,
    confirmLabel: l10n.availabilityDeleteVacationConfirm,
    cancelLabel: l10n.cancel,
  );
  return confirmed == true;
}
