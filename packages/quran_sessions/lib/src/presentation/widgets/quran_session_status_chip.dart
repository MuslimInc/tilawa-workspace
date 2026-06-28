import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../theme/quran_sessions_status_colors.dart';

/// Compact status chip for student session rows.
class QuranSessionStatusChip extends StatelessWidget {
  const QuranSessionStatusChip({
    super.key,
    required this.session,
    this.startsSoon = false,
  });

  final QuranSession session;
  final bool startsSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final status = context.quranSessionsStatus;
    final tint = Theme.of(context).tokens.opacitySubtle;
    final lifecycle = session.effectiveLifecycleStatus;

    if (startsSoon && lifecycle.canJoinSession) {
      return _statusChip(
        context,
        label: l10n.sessionStatusStartingSoon,
        background: status.joinAvailable.withValues(alpha: tint),
        foreground: status.joinAvailable,
      );
    }

    final (label, bg, fg) = switch (lifecycle) {
      SessionLifecycleStatus.pendingTutorApproval => (
        l10n.sessionStatusBookingUnderReview,
        status.upcoming.withValues(alpha: tint),
        status.upcoming,
      ),
      SessionLifecycleStatus.rejectedByTutor => (
        l10n.sessionStatusRejectedByTutor,
        status.rejected.withValues(alpha: tint),
        status.rejected,
      ),
      SessionLifecycleStatus.expired => (
        l10n.sessionStatusNoShow,
        status.missed.withValues(alpha: tint),
        status.missed,
      ),
      SessionLifecycleStatus.completed => (
        l10n.sessionStatusCompleted,
        status.completed.withValues(alpha: tint),
        status.completed,
      ),
      SessionLifecycleStatus.cancelledByTeacher ||
      SessionLifecycleStatus.cancelledByStudent ||
      SessionLifecycleStatus.cancelledByAdmin => (
        l10n.sessionStatusCancelled,
        status.cancelled.withValues(alpha: tint),
        status.cancelled,
      ),
      SessionLifecycleStatus.inProgress => (
        l10n.sessionStatusInProgress,
        status.joinAvailable.withValues(alpha: tint),
        status.joinAvailable,
      ),
      SessionLifecycleStatus.scheduled ||
      SessionLifecycleStatus.confirmed ||
      SessionLifecycleStatus.rescheduled => (
        l10n.sessionStatusScheduled,
        status.upcoming.withValues(alpha: tint),
        status.upcoming,
      ),
      _ => switch (session.status) {
        QuranSessionStatus.scheduled => (
          l10n.sessionStatusScheduled,
          status.upcoming.withValues(alpha: tint),
          status.upcoming,
        ),
        QuranSessionStatus.inProgress => (
          l10n.sessionStatusInProgress,
          status.joinAvailable.withValues(alpha: tint),
          status.joinAvailable,
        ),
        QuranSessionStatus.completed => (
          l10n.sessionStatusCompleted,
          status.completed.withValues(alpha: tint),
          status.completed,
        ),
        QuranSessionStatus.cancelledByStudent ||
        QuranSessionStatus.cancelledByTeacher => (
          l10n.sessionStatusCancelled,
          status.cancelled.withValues(alpha: tint),
          status.cancelled,
        ),
        QuranSessionStatus.noShow => (
          l10n.sessionStatusNoShow,
          status.missed.withValues(alpha: tint),
          status.missed,
        ),
      },
    };

    final isDangerChip =
        lifecycle == SessionLifecycleStatus.rejectedByTutor ||
        lifecycle == SessionLifecycleStatus.cancelledByTeacher ||
        lifecycle == SessionLifecycleStatus.cancelledByStudent ||
        lifecycle == SessionLifecycleStatus.cancelledByAdmin ||
        session.status == QuranSessionStatus.cancelledByStudent ||
        session.status == QuranSessionStatus.cancelledByTeacher;

    return _statusChip(
      context,
      label: label,
      background: bg,
      foreground: fg,
      borderColor: isDangerChip ? fg.withValues(alpha: tint * 2.5) : null,
    );
  }
}

/// Renders a student session status badge via the kit [TilawaChip],
/// matching [TutorSessionStatusChip] padding so both rails align.
Widget _statusChip(
  BuildContext context, {
  required String label,
  required Color background,
  required Color foreground,
  Color? borderColor,
}) {
  final theme = Theme.of(context);
  final tokens = theme.tokens;
  final chipTokens = theme.componentTokens.chip;
  return TilawaChip(
    label: label,
    backgroundColor: background,
    foregroundColor: foreground,
    borderColor: borderColor,
    showShadow: false,
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spaceSmall,
      vertical: tokens.spaceExtraSmall,
    ),
    textStyle: theme.textTheme.labelSmall?.copyWith(
      fontWeight: chipTokens.statusFontWeight,
      color: foreground,
      letterSpacing: chipTokens.statusLetterSpacing,
    ),
  );
}
