import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_lifecycle_status.dart';

/// Compact status chip for tutor dashboard session rows.
class TutorSessionStatusChip extends StatelessWidget {
  const TutorSessionStatusChip({super.key, required this.session});

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final lifecycle = session.effectiveLifecycleStatus;

    final (label, bg, fg) = switch (lifecycle) {
      SessionLifecycleStatus.pendingTutorApproval => (
        l10n.tutorSessionStatusPendingApproval,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      SessionLifecycleStatus.rejectedByTutor => (
        l10n.tutorSessionStatusRejected,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      SessionLifecycleStatus.expired => (
        l10n.tutorSessionStatusExpired,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      SessionLifecycleStatus.completed => (
        l10n.tutorSessionStatusCompleted,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      SessionLifecycleStatus.cancelledByTeacher => (
        l10n.tutorSessionStatusCancelledByTutor,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      SessionLifecycleStatus.cancelledByStudent => (
        l10n.tutorSessionStatusCancelledByStudent,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      SessionLifecycleStatus.inProgress => (
        l10n.sessionStatusInProgress,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      SessionLifecycleStatus.scheduled ||
      SessionLifecycleStatus.confirmed ||
      SessionLifecycleStatus.rescheduled => (
        l10n.tutorSessionStatusAccepted,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _ => switch (session.status) {
        QuranSessionStatus.scheduled => (
          l10n.tutorSessionStatusAccepted,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
        QuranSessionStatus.inProgress => (
          l10n.sessionStatusInProgress,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
        QuranSessionStatus.completed => (
          l10n.tutorSessionStatusCompleted,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
        QuranSessionStatus.cancelledByStudent => (
          l10n.tutorSessionStatusCancelledByStudent,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
        QuranSessionStatus.cancelledByTeacher => (
          l10n.tutorSessionStatusCancelledByTutor,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
        QuranSessionStatus.noShow => (
          l10n.sessionStatusNoShow,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      },
    };

    return TilawaStatusChip(
      label: label,
      backgroundColor: bg,
      foregroundColor: fg,
      padding: EdgeInsets.symmetric(
        horizontal: Theme.of(context).tokens.spaceSmall,
        vertical: Theme.of(context).tokens.spaceExtraSmall,
      ),
    );
  }
}
