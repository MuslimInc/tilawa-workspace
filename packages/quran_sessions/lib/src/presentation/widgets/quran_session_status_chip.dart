import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../theme/quran_sessions_theme.dart';

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
    final feature = context.quranSessionsTheme;
    final tint = Theme.of(context).tokens.opacitySubtle;
    final lifecycle = session.effectiveLifecycleStatus;

    if (startsSoon && lifecycle.canJoinSession) {
      return _Chip(
        label: l10n.sessionStatusStartingSoon,
        background: feature.joinAvailable.withValues(alpha: tint),
        foreground: feature.joinAvailable,
      );
    }

    final (label, bg, fg) = switch (lifecycle) {
      SessionLifecycleStatus.pendingTutorApproval => (
        l10n.sessionStatusPendingTutorApproval,
        feature.upcomingStatus.withValues(alpha: tint),
        feature.upcomingStatus,
      ),
      SessionLifecycleStatus.rejectedByTutor => (
        l10n.sessionStatusRejectedByTutor,
        feature.destructiveSoft,
        feature.destructive,
      ),
      SessionLifecycleStatus.expired => (
        l10n.sessionStatusNoShow,
        feature.missedStatus.withValues(alpha: tint),
        feature.missedStatus,
      ),
      SessionLifecycleStatus.completed => (
        l10n.sessionStatusCompleted,
        feature.completedStatus.withValues(alpha: tint),
        feature.completedStatus,
      ),
      SessionLifecycleStatus.cancelledByTeacher ||
      SessionLifecycleStatus.cancelledByStudent ||
      SessionLifecycleStatus.cancelledByAdmin => (
        l10n.sessionStatusCancelled,
        feature.destructiveSoft,
        feature.cancelledStatus,
      ),
      SessionLifecycleStatus.inProgress => (
        l10n.sessionStatusInProgress,
        feature.joinAvailable.withValues(alpha: tint),
        feature.joinAvailable,
      ),
      SessionLifecycleStatus.scheduled ||
      SessionLifecycleStatus.confirmed ||
      SessionLifecycleStatus.rescheduled => (
        l10n.sessionStatusScheduled,
        feature.upcomingStatus.withValues(alpha: tint),
        feature.upcomingStatus,
      ),
      _ => switch (session.status) {
        QuranSessionStatus.scheduled => (
          l10n.sessionStatusScheduled,
          feature.upcomingStatus.withValues(alpha: tint),
          feature.upcomingStatus,
        ),
        QuranSessionStatus.inProgress => (
          l10n.sessionStatusInProgress,
          feature.joinAvailable.withValues(alpha: tint),
          feature.joinAvailable,
        ),
        QuranSessionStatus.completed => (
          l10n.sessionStatusCompleted,
          feature.completedStatus.withValues(alpha: tint),
          feature.completedStatus,
        ),
        QuranSessionStatus.cancelledByStudent ||
        QuranSessionStatus.cancelledByTeacher => (
          l10n.sessionStatusCancelled,
          feature.destructiveSoft,
          feature.cancelledStatus,
        ),
        QuranSessionStatus.noShow => (
          l10n.sessionStatusNoShow,
          feature.missedStatus.withValues(alpha: tint),
          feature.missedStatus,
        ),
      },
    };

    return _Chip(label: label, background: bg, foreground: fg);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: feature.listItemGap,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(feature.chipRadius),
      ),
      child: Text(
        label,
        style: feature.chipLabelStyle.copyWith(color: foreground),
      ),
    );
  }
}
