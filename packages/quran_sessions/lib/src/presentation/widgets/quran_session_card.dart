import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../session_join/session_join_ui_state.dart';
import '../theme/quran_sessions_theme.dart';
import 'quran_session_action_menu.dart';
import 'quran_session_status_chip.dart';
import 'quran_sessions_surface_card.dart';

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
  final bool isJoinLoading;
  final QuranSessionCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: feature.cardPaddingInsets(),
      child: QuranSessionsSurfaceCard(
        highlighted: highlighted,
        onTap: onTap ?? onViewDetails,
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
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
                  style: feature.cardTitleStyle,
                ),
        ),
        QuranSessionStatusChip(session: session, startsSoon: startsSoon),
        SizedBox(width: tokens.spaceExtraSmall),
        Icon(
          _callTypeIcon(session.callType),
          size: tokens.iconSizeSmall,
          color: feature.helperTextColor,
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
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
            style: feature.cardTitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        Expanded(
          child: Text(
            context.quranSessionsL10n.callTypeLabel(session.callType),
            style: feature.cardMetaStyle,
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: feature.accentSoftBackground,
        borderRadius: BorderRadius.circular(feature.dateChipRadius),
      ),
      child: Column(
        children: [
          Text(
            top,
            style: feature.summaryLabelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            bottom,
            style: feature.cardMetaStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    final joinUiState = resolveSessionJoinUiState(
      lifecycleStatus: session.effectiveLifecycleStatus,
      startsAt: session.startsAt,
      now: now,
      joinInProgress: isJoinLoading,
      joinFailure: null,
      hasOpenedMeeting: false,
    );

    final showJoin =
        onJoin != null &&
        (joinUiState == SessionJoinUiState.joinAvailable ||
            joinUiState == SessionJoinUiState.joining ||
            joinUiState == SessionJoinUiState.notStarted);
    final joinEnabled = joinUiState == SessionJoinUiState.joinAvailable;
    final minutesUntilStart = session.startsAt.difference(now).inMinutes;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: Row(
        children: [
          if (joinUiState == SessionJoinUiState.notStarted &&
              minutesUntilStart > 0)
            Expanded(
              child: Text(
                l10n.sessionStartsInMinutes(minutesUntilStart),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: feature.cardMetaStyle,
              ),
            )
          else
            const Spacer(),
          if (showJoin) ...[
            _SessionJoinButton(
              label: joinEnabled ? l10n.joinSessionNow : l10n.joinSession,
              enabled: joinEnabled && !isJoinLoading,
              isLoading: isJoinLoading,
              onPressed: onJoin,
            ),
            SizedBox(width: tokens.spaceExtraSmall),
          ],
          QuranSessionActionMenu(
            onViewDetails: onViewDetails,
            onReschedule: onReschedule,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}

class _SessionJoinButton extends StatelessWidget {
  const _SessionJoinButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final foreground = enabled
        ? feature.onPrimaryColor
        : feature.joinUnavailable;
    final background = enabled
        ? feature.joinAvailable
        : feature.disabledBackground;
    final border = enabled ? feature.joinAvailable : feature.disabledBorder;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: tokens.minInteractiveDimension,
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled && !isLoading ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: tokens.iconSizeSmall,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: feature.chipLabelStyle.copyWith(
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PastActionsRow extends StatelessWidget {
  const _PastActionsRow({
    required this.onViewDetails,
    required this.onBookAgain,
  });

  final VoidCallback? onViewDetails;
  final VoidCallback? onBookAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    if (onViewDetails == null && onBookAgain == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onViewDetails != null)
            TextButton(
              onPressed: onViewDetails,
              child: Text(l10n.viewSessionDetails),
            ),
          if (onBookAgain != null)
            TextButton(
              onPressed: onBookAgain,
              child: Text(l10n.bookAgainAction),
            ),
        ],
      ),
    );
  }
}
