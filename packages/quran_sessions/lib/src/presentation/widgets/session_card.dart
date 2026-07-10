import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_lifecycle_status.dart';

/// Card showing session time, teacher name, and status badge.
/// Used in [MySessionsScreen] and [TeacherDashboardScreen].
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.teacherName,
    this.onTap,
    this.onJoin,
    this.onCancel,
    this.isJoinLoading = false,
    this.showCancelInOverflowMenu = false,
  });

  final QuranSession session;

  /// Optional resolved teacher name (fetched by host from store).
  final String? teacherName;

  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
  final bool isJoinLoading;

  /// When true, [onCancel] appears in a card overflow menu instead of the
  /// action row (teacher dashboard upcoming sessions).
  final bool showCancelInOverflowMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = Theme.of(context).tokens;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEEE، d MMMM y', locale);
    final timeFmt = DateFormat('h:mm a', locale);
    final localStart = session.startsAt.toLocal();
    final showCancelButton = onCancel != null && !showCancelInOverflowMenu;
    final showCancelOverflow = onCancel != null && showCancelInOverflowMenu;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TilawaCard(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (teacherName != null)
                            Text(
                              teacherName!,
                              style: textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            dateFmt.format(localStart),
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            timeFmt.format(localStart),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showCancelOverflow)
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            color: scheme.surface,
                            surfaceTintColor: scheme.surfaceTint,
                          ),
                        ),
                        child: PopupMenuButton<void>(
                          icon: Icon(
                            Icons.more_vert,
                            color: scheme.onSurfaceVariant,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem<void>(
                              onTap: onCancel,
                              child: Text(l10n.tutorCancelSessionFromCard),
                            ),
                          ],
                        ),
                      ),
                    _StatusBadge(session: session),
                  ],
                ),
              ],
            ),
          ),
          if (onJoin != null || showCancelButton) ...[
            SizedBox(height: tokens.spaceSmall + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCancelButton)
                  TilawaButton(
                    text: l10n.cancel,
                    variant: TilawaButtonVariant.dangerOutline,
                    size: TilawaButtonSize.small,
                    onPressed: onCancel,
                  ),
                if (onJoin != null) ...[
                  SizedBox(width: tokens.spaceSmall),
                  TilawaButton(
                    text: l10n.joinSession,
                    variant: TilawaButtonVariant.primary,
                    size: TilawaButtonSize.small,
                    isLoading: isJoinLoading,
                    onPressed: isJoinLoading ? null : onJoin,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.session});

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final lifecycle = session.effectiveLifecycleStatus;

    final (label, bg, fg) = switch (lifecycle) {
      SessionLifecycleStatus.pendingTutorApproval => (
        l10n.sessionStatusBookingUnderReview,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      SessionLifecycleStatus.rejectedByTutor => (
        l10n.sessionStatusRejectedByTutor,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _ => switch (session.status) {
        QuranSessionStatus.scheduled => (
          l10n.sessionStatusScheduled,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
        QuranSessionStatus.inProgress => (
          l10n.sessionStatusInProgress,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
        QuranSessionStatus.completed => (
          l10n.sessionStatusCompleted,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
        QuranSessionStatus.cancelledByStudent ||
        QuranSessionStatus.cancelledByTeacher => (
          l10n.sessionStatusCancelled,
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
    );
  }
}
