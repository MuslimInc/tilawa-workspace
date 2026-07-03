import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../session_join/session_join_ui_state.dart';
import 'quran_session_action_menu.dart';
import 'quran_session_status_chip.dart';

/// Compact student session card for My Sessions dashboard.
class QuranSessionCard extends StatelessWidget {
  const QuranSessionCard({
    super.key,
    required this.session,
    required this.now,
    this.teacherName,
    this.highlighted = false,
    this.onTap,
    this.onJoin,
    this.onViewDetails,
    this.onReschedule,
    this.onCancel,
    this.onBookAgain,
    this.onReview,
    this.isJoinLoading = false,
    this.variant = QuranSessionCardVariant.upcoming,
  });

  final QuranSession session;
  final DateTime now;
  final String? teacherName;
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onBookAgain;
  final VoidCallback? onReview;
  final bool isJoinLoading;
  final QuranSessionCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceExtraSmall,
      ),
      child: TilawaCard(
        onTap: onTap ?? onViewDetails,
        padding: EdgeInsets.all(tokens.spaceSmall),
        borderColor: highlighted
            ? scheme.primary.withValues(alpha: 0.35)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SessionHeaderRow(
              session: session,
              teacherName: teacherName,
              now: now,
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            _SessionDateTimeRow(session: session),
            if (variant == QuranSessionCardVariant.upcoming &&
                session.effectiveLifecycleStatus ==
                    SessionLifecycleStatus.pendingTutorApproval)
              _PendingTutorApprovalBanner(session: session),
            if (variant == QuranSessionCardVariant.upcoming)
              _UpcomingActionsRow(
                session: session,
                now: now,
                onJoin: onJoin,
                isJoinLoading: isJoinLoading,
                onViewDetails: onViewDetails,
                onReschedule: onReschedule,
                onCancel: onCancel,
              )
            else
              _PastActionsRow(
                onViewDetails: onViewDetails,
                onBookAgain: onBookAgain,
                onReview: onReview,
              ),
          ],
        ),
      ),
    );
  }
}

enum QuranSessionCardVariant { upcoming, past, cancelled }

class _SessionHeaderRow extends StatelessWidget {
  const _SessionHeaderRow({
    required this.session,
    required this.teacherName,
    required this.now,
  });

  final QuranSession session;
  final String? teacherName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final startsSoon = _isStartingSoon(session, now);

    return Row(
      children: [
        Expanded(
          child: teacherName == null
              ? const SizedBox.shrink()
              : Text(
                  teacherName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
        ),
        QuranSessionStatusChip(session: session, startsSoon: startsSoon),
        SizedBox(width: tokens.spaceExtraSmall),
        Icon(
          _callTypeIcon(session.callType),
          size: tokens.iconSizeSmall,
          color: scheme.onSurfaceVariant,
          semanticLabel: context.quranSessionsL10n.callTypeLabel(
            session.callType,
          ),
        ),
      ],
    );
  }

  bool _isStartingSoon(QuranSession session, DateTime now) {
    final diff = session.startsAt.difference(now);
    return diff.inMinutes > 0 &&
        diff.inMinutes <= 30 &&
        session.effectiveLifecycleStatus.canJoinSession;
  }

  IconData _callTypeIcon(SessionCallType type) => switch (type) {
    SessionCallType.voiceCall => Icons.call_outlined,
    SessionCallType.videoCall => Icons.videocam_outlined,
    SessionCallType.externalMeeting => Icons.link_outlined,
  };
}

class _SessionDateTimeRow extends StatelessWidget {
  const _SessionDateTimeRow({required this.session});

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;
    final locale = Localizations.localeOf(context).languageCode;
    final localStart = session.startsAt.toLocal();
    final dayFmt = DateFormat('EEEE', locale);
    final dateFmt = DateFormat('d MMMM', locale);
    final timeFmt = DateFormat('h:mm a', locale);

    return Row(
      children: [
        _DateChip(
          top: dayFmt.format(localStart),
          bottom: dateFmt.format(localStart),
        ),
        SizedBox(width: tokens.spaceSmall),
        Flexible(
          child: Text(
            timeFmt.format(localStart),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        Expanded(
          child: Text(
            context.quranSessionsL10n.callTypeLabel(session.callType),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.top, required this.bottom});

  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chip),
        ),
      ),
      child: Column(
        children: [
          Text(
            top,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            bottom,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PendingTutorApprovalBanner extends StatelessWidget {
  const _PendingTutorApprovalBanner({required this.session});

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: TilawaFeedbackStrip(
        icon: Icons.hourglass_top_rounded,
        message: l10n.sessionAwaitingTeacherApprovalHint,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        variant: TilawaFeedbackVariant.info,
      ),
    );
  }
}

class _UpcomingActionsRow extends StatelessWidget {
  const _UpcomingActionsRow({
    required this.session,
    required this.now,
    required this.onJoin,
    required this.isJoinLoading,
    required this.onViewDetails,
    required this.onReschedule,
    required this.onCancel,
  });

  final QuranSession session;
  final DateTime now;
  final VoidCallback? onJoin;
  final bool isJoinLoading;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    final joinUiState = resolveSessionJoinUiState(
      lifecycleStatus: session.effectiveLifecycleStatus,
      startsAt: session.startsAt,
      endsAt: session.endsAt,
      now: now,
      joinInProgress: isJoinLoading,
      joinFailure: null,
      hasOpenedMeeting: false,
    );

    if (joinUiState == SessionJoinUiState.awaitingTutorApproval) {
      return Padding(
        padding: EdgeInsets.only(top: tokens.spaceSmall),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: QuranSessionActionMenu(
            onViewDetails: onViewDetails,
            onReschedule: null,
            onCancel: onCancel,
          ),
        ),
      );
    }

    final showJoin =
        onJoin != null &&
        (joinUiState == SessionJoinUiState.joinAvailable ||
            joinUiState == SessionJoinUiState.joining ||
            joinUiState == SessionJoinUiState.notStarted);
    final joinEnabled = joinUiState == SessionJoinUiState.joinAvailable;
    final minutesUntilStart = session.startsAt.difference(now).inMinutes;

    final showCountdown =
        joinUiState == SessionJoinUiState.notStarted && minutesUntilStart > 0;

    final actionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showJoin) ...[
          TilawaButton(
            text: joinEnabled ? l10n.joinSessionNow : l10n.joinSession,
            onPressed: joinEnabled && !isJoinLoading ? onJoin : null,
            isLoading: isJoinLoading,
            size: TilawaButtonSize.small,
          ),
          SizedBox(width: tokens.spaceSmall),
        ],
        QuranSessionActionMenu(
          onViewDetails: onViewDetails,
          onReschedule: onReschedule,
          onCancel: onCancel,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCountdown) ...[
            Text(
              l10n.sessionStartsInMinutes(minutesUntilStart),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: actionRow,
          ),
        ],
      ),
    );
  }
}

class _PastActionsRow extends StatelessWidget {
  const _PastActionsRow({
    required this.onViewDetails,
    required this.onBookAgain,
    required this.onReview,
  });

  final VoidCallback? onViewDetails;
  final VoidCallback? onBookAgain;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    if (onViewDetails == null && onBookAgain == null && onReview == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: tokens.spaceExtraSmall,
          children: [
            if (onReview != null)
              TilawaButton(
                text: l10n.rateSessionAction,
                onPressed: onReview,
                variant: TilawaButtonVariant.ghost,
                size: TilawaButtonSize.small,
              ),
            if (onViewDetails != null)
              TilawaButton(
                text: l10n.viewSessionDetails,
                onPressed: onViewDetails,
                variant: TilawaButtonVariant.ghost,
                size: TilawaButtonSize.small,
              ),
            if (onBookAgain != null)
              TilawaButton(
                text: l10n.bookAgainAction,
                onPressed: onBookAgain,
                variant: TilawaButtonVariant.ghost,
                size: TilawaButtonSize.small,
              ),
          ],
        ),
      ),
    );
  }
}
