import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import '../widgets/quran_sessions_offline_state.dart';
import 'quran_sessions_failure_ui.dart';

/// Builds the primary body for a failed Quran Sessions load.
Widget buildQuranSessionsFailureBody(
  BuildContext context, {
  required QuranSessionsFailure failure,
  required VoidCallback onRetry,
  bool isRetrying = false,
}) {
  if (failure is NetworkFailure) {
    return QuranSessionsOfflineState(
      onRetry: onRetry,
      isRetrying: isRetrying,
    );
  }

  final l10n = context.quranSessionsL10n;

  return TilawaErrorState(
    icon: Icons.error_outline,
    title: failure.toLocalizedMessage(context),
    retryLabel: l10n.retry,
    onRetry: onRetry,
    isRetrying: isRetrying,
  );
}
