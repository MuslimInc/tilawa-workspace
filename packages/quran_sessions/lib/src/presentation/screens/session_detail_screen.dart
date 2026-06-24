import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../l10n/session_lifecycle_l10n.dart';
import '../widgets/pending_reschedule_banner.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.bookingId,
    this.createCallControlGateway,
    this.buildCallSurface,
  });

  final String bookingId;
  final SessionCallControlGatewayFactory? createCallControlGateway;
  final InAppCallSurfaceBuilder? buildCallSurface;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with WidgetsBindingObserver {
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionDetailTitle)),
      bottomNavigationBar: BlocBuilder<SessionDetailBloc, SessionDetailState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType ||
            (current is SessionDetailSuccess &&
                previous is SessionDetailSuccess &&
                (previous.canJoin != current.canJoin ||
                    previous.canOpenDispute != current.canOpenDispute ||
                    previous.canOpenMeetingAgain !=
                        current.canOpenMeetingAgain ||
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
                  padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
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
                          onAccept: () => context.read<SessionDetailBloc>().add(
                            const SessionDetailRescheduleRespondSubmitted(
                              accept: true,
                            ),
                          ),
                          onReject: () => context.read<SessionDetailBloc>().add(
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
                    SizedBox(height: Theme.of(context).tokens.spaceExtraLarge),
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
    );
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
}
