import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../session_join/session_join_ui_state.dart';
import '../l10n/session_join_l10n.dart';
import '../l10n/session_lifecycle_l10n.dart';
import '../utils/session_revision_practice.dart';
import '../widgets/pending_reschedule_banner.dart';
import '../widgets/session_revision_practice_card.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.bookingId,
    this.createCallControlGateway,
    this.createCallTelemetry,
    this.buildCallSurface,
    this.onPracticeRevisionRequested,
  });

  final String bookingId;
  final SessionCallControlGatewayFactory? createCallControlGateway;
  final CallTelemetryCoordinatorFactory? createCallTelemetry;
  final InAppCallSurfaceBuilder? buildCallSurface;

  /// Host opens Tilawa Quran reader for [surahNumber] (optional [ayahNumber]).
  final void Function({required int surahNumber, int? ayahNumber})?
  onPracticeRevisionRequested;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with WidgetsBindingObserver {
  /// Set when tutor cancels so parent list can refresh on pop.
  bool _notifyParentOnPop = false;
  bool _didAutoPromptReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SessionDetailBloc>().add(
      SessionDetailLoadRequested(bookingId: widget.bookingId),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final blocState = context.read<SessionDetailBloc>().state;
    if (blocState is! SessionDetailSuccess) return;
    if (blocState.isAwaitingRescheduleCounterparty ||
        blocState.aggregate.lifecycleStatus ==
            SessionLifecycleStatus.rescheduled) {
      _reloadDetail();
    }
  }

  Future<void> _reloadDetail() async {
    final bloc = context.read<SessionDetailBloc>();
    bloc.add(SessionDetailLoadRequested(bookingId: widget.bookingId));
    await bloc.stream.firstWhere((s) => s is! SessionDetailLoading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_notifyParentOnPop ? true : null);
      },
      child: QuranSessionsScaffold(
        title: l10n.sessionDetailTitle,
        bottomNavigationBar: BlocBuilder<SessionDetailBloc, SessionDetailState>(
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType ||
              (current is SessionDetailSuccess &&
                  previous is SessionDetailSuccess &&
                  (previous.canJoin != current.canJoin ||
                      previous.canCancel != current.canCancel ||
                      previous.joinUiState != current.joinUiState ||
                      previous.cancellationInProgress !=
                          current.cancellationInProgress ||
                      previous.canOpenDispute != current.canOpenDispute ||
                      previous.canOpenMeetingAgain !=
                          current.canOpenMeetingAgain ||
                      previous.canReview != current.canReview ||
                      previous.joinInProgress != current.joinInProgress)),
          builder: (context, state) {
            if (state is! SessionDetailSuccess) {
              return const SizedBox.shrink();
            }
            return _SessionDetailFooter(state: state);
          },
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  previous is SessionDetailSuccess &&
                  current is SessionDetailSuccess &&
                  previous.joinInProgress &&
                  !current.joinInProgress,
              listener: (context, state) async {
                if (state is! SessionDetailSuccess) return;

                if (state.joinFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.joinFailure!.toLocalizedMessage(context),
                    variant: TilawaFeedbackVariant.error,
                  );
                  return;
                }

                if (!state.isExternalMeeting &&
                    state.aggregate.sessionId != null) {
                  final sessionId = state.aggregate.sessionId!;
                  final callType = state.callType ?? SessionCallType.voiceCall;
                  final callProviderKind =
                      state.callProviderKind ?? SessionCallProviderKind.mock;
                  await pushInAppCallShell(
                    context,
                    sessionId: sessionId,
                    callType: callType,
                    callProviderKind: callProviderKind,
                    participantSubtitle: l10n.callTypeLabel(callType),
                    buildCallSurface: widget.buildCallSurface,
                    createCallControlGateway: widget.createCallControlGateway,
                    createCallTelemetry: widget.createCallTelemetry,
                  );
                }
              },
            ),
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  current is SessionDetailSuccess &&
                  ((previous is! SessionDetailSuccess) ||
                      previous.reportFailure != current.reportFailure ||
                      previous.reportSubmitted != current.reportSubmitted ||
                      previous.disputeFailure != current.disputeFailure ||
                      previous.disputeSubmitted != current.disputeSubmitted),
              listener: (context, state) {
                if (state is SessionDetailSuccess &&
                    state.reportFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.reportFailure!.toLocalizedMessage(context),
                    variant: TilawaFeedbackVariant.error,
                  );
                }
                if (state is SessionDetailSuccess && state.reportSubmitted) {
                  TilawaFeedback.showToast(
                    context,
                    message: l10n.reportConcernSubmitted,
                    variant: TilawaFeedbackVariant.success,
                  );
                  context.read<SessionDetailBloc>().add(
                    const SessionDetailReportAcknowledged(),
                  );
                }
                if (state is SessionDetailSuccess &&
                    state.disputeFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.disputeFailure!.toLocalizedMessage(context),
                    variant: TilawaFeedbackVariant.error,
                  );
                }
                if (state is SessionDetailSuccess && state.disputeSubmitted) {
                  TilawaFeedback.showToast(
                    context,
                    message: l10n.openDisputeSubmitted,
                    variant: TilawaFeedbackVariant.success,
                  );
                  context.read<SessionDetailBloc>().add(
                    const SessionDetailDisputeAcknowledged(),
                  );
                }
              },
            ),
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  current is SessionDetailSuccess &&
                  ((previous is! SessionDetailSuccess) ||
                      previous.cancellationFailure !=
                          current.cancellationFailure ||
                      previous.cancellationSucceeded !=
                          current.cancellationSucceeded),
              listener: (context, state) {
                if (state is! SessionDetailSuccess) return;
                if (state.cancellationFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.isTeacherViewer
                        ? l10n.tutorCancelSessionError
                        : state.cancellationFailure!.toLocalizedMessage(
                            context,
                          ),
                    variant: TilawaFeedbackVariant.error,
                  );
                }
                if (state.cancellationSucceeded) {
                  if (state.isTeacherViewer) {
                    setState(() => _notifyParentOnPop = true);
                  }
                  TilawaFeedback.showToast(
                    context,
                    message: state.isTeacherViewer
                        ? l10n.tutorCancelSessionSuccess
                        : l10n.sessionCancelledSuccess,
                    variant: TilawaFeedbackVariant.success,
                  );
                  context.read<SessionDetailBloc>().add(
                    const SessionDetailCancelAcknowledged(),
                  );
                }
              },
            ),
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  current is SessionDetailSuccess &&
                  ((previous is! SessionDetailSuccess) ||
                      previous.reviewFailure != current.reviewFailure ||
                      previous.reviewSubmitted != current.reviewSubmitted),
              listener: (context, state) {
                if (state is! SessionDetailSuccess) return;
                if (state.reviewFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.reviewFailure!.toLocalizedMessage(context),
                    variant: TilawaFeedbackVariant.error,
                  );
                }
                if (state.reviewSubmitted) {
                  TilawaFeedback.showToast(
                    context,
                    message: l10n.reviewSubmittedThanks,
                    variant: TilawaFeedbackVariant.success,
                  );
                  context.read<SessionDetailBloc>().add(
                    const SessionDetailReviewAcknowledged(),
                  );
                }
              },
            ),
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  current is SessionDetailSuccess &&
                  previous is! SessionDetailSuccess,
              listener: (context, state) {
                if (state is! SessionDetailSuccess || _didAutoPromptReview) {
                  return;
                }
                if (!state.canReview) return;
                _didAutoPromptReview = true;
                unawaited(submitSessionReview(context));
              },
            ),
            BlocListener<SessionDetailBloc, SessionDetailState>(
              listenWhen: (previous, current) =>
                  current is SessionDetailSuccess &&
                  ((previous is! SessionDetailSuccess) ||
                      previous.rescheduleRespondFailure !=
                          current.rescheduleRespondFailure ||
                      previous.rescheduleRespondAccepted !=
                          current.rescheduleRespondAccepted),
              listener: (context, state) {
                if (state is! SessionDetailSuccess) return;
                if (state.rescheduleRespondFailure != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: state.rescheduleRespondFailure!.toLocalizedMessage(
                      context,
                    ),
                    variant: TilawaFeedbackVariant.error,
                  );
                }
                final accepted = state.rescheduleRespondAccepted;
                if (accepted != null) {
                  TilawaFeedback.showToast(
                    context,
                    message: accepted
                        ? l10n.rescheduleAcceptedToast
                        : l10n.rescheduleRejectedToast,
                    variant: TilawaFeedbackVariant.success,
                  );
                  context.read<SessionDetailBloc>().add(
                    const SessionDetailRescheduleRespondAcknowledged(),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<SessionDetailBloc, SessionDetailState>(
            builder: (context, state) => switch (state) {
              SessionDetailInitial() || SessionDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              SessionDetailFailure(:final failure) => Center(
                child: Text(failure.toLocalizedMessage(context)),
              ),
              SessionDetailSuccess(
                :final aggregate,
                :final timeline,
                :final callType,
                :final callProviderKind,
                :final timelineLoadFailed,
                :final pendingRescheduleLoadFailed,
                :final pendingRescheduleRequest,
                :final canRespondToReschedule,
                :final isAwaitingRescheduleCounterparty,
                :final rescheduleRespondInProgress,
              ) =>
                RefreshIndicator(
                  onRefresh: _reloadDetail,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      Theme.of(context).tokens.spaceLarge,
                    ),
                    children: [
                      if (pendingRescheduleLoadFailed)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: Theme.of(context).tokens.spaceLarge,
                          ),
                          child: _SessionDetailLoadWarning(
                            message: l10n.sessionPendingRescheduleLoadFailed,
                            bookingId: widget.bookingId,
                          ),
                        ),
                      if (pendingRescheduleRequest != null)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: Theme.of(context).tokens.spaceLarge,
                          ),
                          child: PendingRescheduleBanner(
                            request: pendingRescheduleRequest,
                            canRespond: canRespondToReschedule,
                            isAwaitingCounterparty:
                                isAwaitingRescheduleCounterparty,
                            respondInProgress: rescheduleRespondInProgress,
                            onAccept: () =>
                                context.read<SessionDetailBloc>().add(
                                  const SessionDetailRescheduleRespondSubmitted(
                                    accept: true,
                                  ),
                                ),
                            onReject: () =>
                                context.read<SessionDetailBloc>().add(
                                  const SessionDetailRescheduleRespondSubmitted(
                                    accept: false,
                                  ),
                                ),
                          ),
                        ),
                      Text(
                        l10n.sessionStatusLabel(
                          aggregate.lifecycleStatus.localizedLabel(l10n),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: Theme.of(context).tokens.spaceSmall),
                      _SessionJoinStateBanner(state: state),
                      if (_showsRevisionPractice(state)) ...[
                        SizedBox(height: Theme.of(context).tokens.spaceLarge),
                        SessionRevisionPracticeCard(
                          surahNumber: state.aggregate.revisionSurahNumber!,
                          ayahNumber: state.aggregate.revisionAyahNumber,
                          isCompletedSession:
                              state.aggregate.lifecycleStatus ==
                              SessionLifecycleStatus.completed,
                          onPracticeTapped: () =>
                              widget.onPracticeRevisionRequested?.call(
                                surahNumber:
                                    state.aggregate.revisionSurahNumber!,
                                ayahNumber: state.aggregate.revisionAyahNumber,
                              ),
                        ),
                      ],
                      SizedBox(height: Theme.of(context).tokens.spaceSmall),
                      Text(
                        l10n.sessionStartsAtLabel(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(aggregate.startsAt.toLocal()),
                        ),
                      ),
                      if (state.showLockedAtBookingCopy &&
                          callType != null &&
                          callProviderKind != null) ...[
                        SizedBox(height: Theme.of(context).tokens.spaceLarge),
                        _LockedAtBookingFootnote(
                          callType: callType,
                          callProviderKind: callProviderKind,
                        ),
                      ],
                      SizedBox(
                        height: Theme.of(context).tokens.spaceExtraLarge,
                      ),
                      Text(
                        l10n.sessionTimelineTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: Theme.of(context).tokens.spaceSmall),
                      if (timelineLoadFailed)
                        _SessionDetailLoadWarning(
                          message: l10n.sessionTimelineLoadFailed,
                          bookingId: widget.bookingId,
                        )
                      else if (timeline.isEmpty)
                        Text(l10n.sessionTimelineEmpty)
                      else
                        ...timeline.map(
                          (event) => ListTile(
                            title: Text(event.action.localizedLabel(l10n)),
                            subtitle: Text(
                              event.reason ??
                                  l10n.sessionTimelineStatusTransition(
                                    event.previousStatus.localizedLabel(l10n),
                                    event.newStatus.localizedLabel(l10n),
                                  ),
                            ),
                            trailing: Text(
                              MaterialLocalizations.of(context).formatShortDate(
                                event.createdAt.toLocal(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            },
          ),
        ),
      ),
    );
  }

  bool _showsRevisionPractice(SessionDetailSuccess state) {
    if (widget.onPracticeRevisionRequested == null) {
      return false;
    }
    if (!state.aggregate.hasRevisionSurahContext) {
      return false;
    }
    return sessionShowsRevisionPractice(state.aggregate.lifecycleStatus);
  }
}

class _LockedAtBookingFootnote extends StatelessWidget {
  const _LockedAtBookingFootnote({
    required this.callType,
    required this.callProviderKind,
  });

  final SessionCallType callType;
  final SessionCallProviderKind callProviderKind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              TilawaIcons.info,
              size: tokens.iconSizeMedium,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: Text(
                l10n.sessionLockedAtBookingNote(
                  l10n.callTypeLabel(callType),
                  l10n.callProviderKindLabel(callProviderKind),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionJoinStateBanner extends StatelessWidget {
  const _SessionJoinStateBanner({required this.state});

  final SessionDetailSuccess state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final joinState = state.joinUiState;
    final lifecycle = state.aggregate.lifecycleStatus;

    if (joinState == SessionJoinUiState.cancelled &&
        lifecycle == SessionLifecycleStatus.cancelledByTeacher &&
        !state.isTeacherViewer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sessionCancelledByTutorTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: Theme.of(context).tokens.spaceExtraSmall),
          Text(
            l10n.sessionCancelledByTutorSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (joinState == SessionJoinUiState.rejectedByTutor &&
        !state.isTeacherViewer) {
      final reason = safeBookingRejectionReasonForDisplay(
        state.aggregate.rejectionReason,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingRejectedTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: Theme.of(context).tokens.spaceExtraSmall),
          Text(
            l10n.bookingRejectedSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (reason != null) ...[
            SizedBox(height: Theme.of(context).tokens.spaceSmall),
            Text(
              reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    if (joinState == SessionJoinUiState.awaitingTutorApproval &&
        !state.isTeacherViewer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bookingRequestSentTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: Theme.of(context).tokens.spaceExtraSmall),
          Text(
            l10n.bookingRequestSentSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: Theme.of(context).tokens.spaceSmall),
          TilawaFeedbackStrip(
            icon: Icons.hourglass_top_rounded,
            message: l10n.sessionAwaitingTutorApprovalNextSteps,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            variant: TilawaFeedbackVariant.info,
          ),
        ],
      );
    }

    final message = joinState.localizedMessage(l10n);
    if (joinState == SessionJoinUiState.joinAvailable) {
      return Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
        ),
      );
    }
    if (joinState == SessionJoinUiState.failed) {
      return TilawaPermissionBanner(
        message: state.joinFailure?.toLocalizedMessage(context) ?? message,
        actionLabel: l10n.retry,
        icon: TilawaIcons.warning,
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        onAction: () => context.read<SessionDetailBloc>().add(
          const SessionDetailJoinRequested(),
        ),
      );
    }
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _SessionDetailLoadWarning extends StatelessWidget {
  const _SessionDetailLoadWarning({
    required this.message,
    required this.bookingId,
  });

  final String message;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;

    return TilawaPermissionBanner(
      message: message,
      actionLabel: l10n.retry,
      icon: TilawaIcons.warning,
      backgroundColor: scheme.errorContainer,
      foregroundColor: scheme.onErrorContainer,
      onAction: () => context.read<SessionDetailBloc>().add(
        SessionDetailLoadRequested(bookingId: bookingId),
      ),
    );
  }
}

class _SessionDetailFooter extends StatelessWidget {
  const _SessionDetailFooter({required this.state});

  final SessionDetailSuccess state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return TilawaBottomActionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: [
          if (state.canJoin)
            TilawaButton(
              text: l10n.joinSession,
              isFullWidth: true,
              size: TilawaButtonSize.large,
              isLoading: state.joinInProgress,
              onPressed: state.joinInProgress
                  ? null
                  : () => _requestJoin(context),
            ),
          if (state.canCancel)
            TilawaButton(
              text: state.isTeacherViewer
                  ? l10n.tutorCancelSessionAction
                  : l10n.cancelSessionAction,
              variant: TilawaButtonVariant.dangerOutline,
              isFullWidth: true,
              isLoading: state.cancellationInProgress,
              onPressed: state.cancellationInProgress
                  ? null
                  : () => _confirmCancel(context),
            ),
          if (state.canOpenMeetingAgain)
            TilawaButton(
              text: l10n.externalMeetingJoinAgain,
              variant: TilawaButtonVariant.outline,
              isFullWidth: true,
              isLoading: state.joinInProgress,
              onPressed: state.joinInProgress
                  ? null
                  : () => context.read<SessionDetailBloc>().add(
                      const SessionDetailOpenMeetingAgainRequested(),
                    ),
            ),
          if (state.canReview)
            TilawaButton(
              text: l10n.rateSessionAction,
              variant: TilawaButtonVariant.secondary,
              isFullWidth: true,
              isLoading: state.reviewInProgress,
              onPressed: state.reviewInProgress
                  ? null
                  : () => submitSessionReview(context),
            ),
          TilawaButton(
            text: l10n.reportConcernAction,
            variant: TilawaButtonVariant.outline,
            isFullWidth: true,
            onPressed: () => _submitReport(context),
          ),
          if (state.canOpenDispute)
            TilawaButton(
              text: l10n.openDisputeAction,
              variant: TilawaButtonVariant.secondary,
              isFullWidth: true,
              isLoading: state.disputeInProgress,
              onPressed: state.disputeInProgress
                  ? null
                  : () => _submitDispute(context),
            ),
        ],
      ),
    );
  }

  Future<void> _requestJoin(BuildContext context) async {
    if (state.isExternalMeeting) {
      final confirmed = await showExternalMeetingJoinSheet(
        context,
        meetingUrl: state.externalMeetingJoinUrl!,
      );
      if (!confirmed || !context.mounted) return;
    }
    context.read<SessionDetailBloc>().add(const SessionDetailJoinRequested());
  }

  Future<void> _submitReport(BuildContext context) async {
    final input = await showReportConcernSheet(context);
    if (input == null || !context.mounted) return;
    context.read<SessionDetailBloc>().add(
      SessionDetailReportSubmitted(
        category: input.category,
        description: input.description,
      ),
    );
  }

  Future<void> _submitDispute(BuildContext context) async {
    final reason = await showOpenDisputeSheet(context);
    if (reason == null || !context.mounted) return;
    context.read<SessionDetailBloc>().add(
      SessionDetailDisputeSubmitted(reason: reason),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    if (state.isTeacherViewer) {
      final confirmed = await showTutorCancelSessionDialog(context);
      if (!confirmed || !context.mounted) return;
      context.read<SessionDetailBloc>().add(
        const SessionDetailCancelSubmitted(reason: tutorCancelSessionReason),
      );
      return;
    }

    final reason = await showCancelSessionSheet(
      context,
      sessionStartsAt: state.aggregate.startsAt,
      pricingType: state.aggregate.pricingType,
    );
    if (reason == null || !context.mounted) return;
    context.read<SessionDetailBloc>().add(
      SessionDetailCancelSubmitted(reason: reason),
    );
  }
}

Future<void> submitSessionReview(BuildContext context) async {
  final input = await showSessionReviewSheet(context);
  if (input == null || !context.mounted) return;
  context.read<SessionDetailBloc>().add(
    SessionDetailReviewSubmitted(
      rating: input.rating,
      comment: input.comment,
    ),
  );
}
