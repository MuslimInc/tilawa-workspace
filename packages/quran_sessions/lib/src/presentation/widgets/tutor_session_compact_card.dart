import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_call_type.dart';
import '../session_join/session_join_ui_state.dart';
import 'teacher_initials_avatar.dart';
import 'tutor_session_status_chip.dart';

/// Dense session row for the tutor dashboard — pending requests and upcoming.
class TutorSessionCompactCard extends StatelessWidget {
  const TutorSessionCompactCard({
    super.key,
    required this.session,
    required this.studentDisplayName,
    required this.now,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onJoin,
    this.onCancel,
    this.isLoading = false,
    this.showCancelInOverflowMenu = false,
  });

  final QuranSession session;
  final String studentDisplayName;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
  final bool isLoading;
  final bool showCancelInOverflowMenu;

  bool get _isPendingRequest => onAccept != null || onReject != null;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TilawaCard(
              surface: TilawaCardSurface.flat,
              padding: EdgeInsets.all(tokens.spaceSmall + 2),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TutorSessionHeaderRow(
                    studentDisplayName: studentDisplayName,
                    session: session,
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  _TutorSessionMetadataRow(session: session),
                  if (_buildActions(context) != null) ...[
                    SizedBox(height: tokens.spaceSmall),
                    _buildActions(context)!,
                  ],
                ],
              ),
            ),
          ),
          if (onCancel != null && showCancelInOverflowMenu)
            _TutorCancelOverflowButton(onCancel: onCancel!),
        ],
      ),
    );
  }

  Widget? _buildActions(BuildContext context) {
    if (_isPendingRequest) {
      return _TutorPendingActionsRow(
        onAccept: onAccept,
        onReject: onReject,
        isLoading: isLoading,
      );
    }

    final joinUiState = resolveSessionJoinUiState(
      lifecycleStatus: session.effectiveLifecycleStatus,
      startsAt: session.startsAt,
      now: now,
      joinInProgress: false,
      joinFailure: null,
      hasOpenedMeeting: false,
    );

    final showJoin =
        onJoin != null &&
        (joinUiState == SessionJoinUiState.joinAvailable ||
            joinUiState == SessionJoinUiState.joining ||
            joinUiState == SessionJoinUiState.notStarted);
    final joinEnabled = joinUiState == SessionJoinUiState.joinAvailable;
    final showNotYetHint = joinUiState == SessionJoinUiState.notStarted;

    if (!showJoin && onCancel == null) return null;

    return _TutorUpcomingActionsRow(
      onJoin: showJoin ? onJoin : null,
      joinEnabled: joinEnabled,
      showNotYetHint: showNotYetHint,
      onCancel: onCancel,
      showCancelInOverflowMenu: showCancelInOverflowMenu,
    );
  }
}

class _TutorSessionHeaderRow extends StatelessWidget {
  const _TutorSessionHeaderRow({
    required this.studentDisplayName,
    required this.session,
  });

  final String studentDisplayName;
  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        TeacherInitialsAvatar(
          displayName: studentDisplayName,
          radius: tokens.iconSizeSmall,
        ),
        SizedBox(width: tokens.spaceSmall),
        Expanded(
          child: Text(
            studentDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        TutorSessionStatusChip(session: session),
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

  IconData _callTypeIcon(SessionCallType type) => switch (type) {
    SessionCallType.voiceCall => Icons.call_outlined,
    SessionCallType.videoCall => Icons.videocam_outlined,
    SessionCallType.externalMeeting => Icons.link_outlined,
  };
}

class _TutorSessionMetadataRow extends StatelessWidget {
  const _TutorSessionMetadataRow({required this.session});

  final QuranSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEE d MMM، h:mm a', locale);
    final localStart = session.startsAt.toLocal();
    final durationMinutes = session.endsAt
        .difference(session.startsAt)
        .inMinutes;
    final durationLabel = l10n.tutorSessionDurationMinutes(durationMinutes);

    return Row(
      children: [
        Icon(
          Icons.schedule_outlined,
          size: tokens.iconSizeSmall,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        Expanded(
          child: Text(
            '$durationLabel · ${dateFmt.format(localStart)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorPendingActionsRow extends StatelessWidget {
  const _TutorPendingActionsRow({
    required this.onAccept,
    required this.onReject,
    required this.isLoading,
  });

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onReject != null)
          TilawaButton(
            text: l10n.teacherRejectBookingRequest,
            variant: TilawaButtonVariant.dangerOutline,
            size: TilawaButtonSize.small,
            onPressed: isLoading ? null : onReject,
          ),
        if (onAccept != null) ...[
          SizedBox(width: tokens.spaceSmall),
          TilawaButton(
            text: l10n.teacherAcceptBookingRequest,
            size: TilawaButtonSize.small,
            isLoading: isLoading,
            onPressed: isLoading ? null : onAccept,
          ),
        ],
      ],
    );
  }
}

class _TutorUpcomingActionsRow extends StatelessWidget {
  const _TutorUpcomingActionsRow({
    required this.onJoin,
    required this.joinEnabled,
    required this.showNotYetHint,
    required this.onCancel,
    required this.showCancelInOverflowMenu,
  });

  final VoidCallback? onJoin;
  final bool joinEnabled;
  final bool showNotYetHint;
  final VoidCallback? onCancel;
  final bool showCancelInOverflowMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final showInlineCancel = onCancel != null && !showCancelInOverflowMenu;

    return Row(
      children: [
        if (showNotYetHint)
          Expanded(
            child: Text(
              l10n.tutorSessionJoinNotYet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          )
        else
          const Spacer(),
        if (showInlineCancel) ...[
          TilawaButton(
            text: l10n.tutorCancelSessionFromCard,
            variant: TilawaButtonVariant.dangerOutline,
            size: TilawaButtonSize.small,
            onPressed: onCancel,
          ),
          SizedBox(width: tokens.spaceSmall),
        ],
        if (onJoin != null)
          TilawaButton(
            text: l10n.joinSession,
            variant: TilawaButtonVariant.primary,
            size: TilawaButtonSize.small,
            onPressed: joinEnabled ? onJoin : null,
          ),
      ],
    );
  }
}

class _TutorCancelOverflowButton extends StatelessWidget {
  const _TutorCancelOverflowButton({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        Icons.more_vert,
        size: tokens.iconSizeSmall,
        color: scheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: tokens.minInteractiveDimension,
        height: tokens.minInteractiveDimension,
      ),
      onPressed: () => _showCancelMenu(context),
    );
  }

  Future<void> _showCancelMenu(BuildContext context) async {
    final l10n = context.quranSessionsL10n;
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'cancel',
          child: Text(l10n.tutorCancelSessionFromCard),
        ),
      ],
    );
    if (!context.mounted || selected != 'cancel') return;
    onCancel();
  }
}
