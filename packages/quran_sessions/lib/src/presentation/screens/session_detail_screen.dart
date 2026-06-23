import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.bookingId,
    this.onLeaveCall,
    this.onSetMicrophoneMuted,
  });

  final String bookingId;
  final Future<void> Function(String sessionId)? onLeaveCall;
  final Future<void> Function(String sessionId, {required bool muted})?
  onSetMicrophoneMuted;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SessionDetailBloc>().add(
      SessionDetailLoadRequested(bookingId: widget.bookingId),
    );
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
            listener: (context, state) {
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
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: 'in_app_call_shell'),
                    builder: (_) => InAppCallShellScreen(
                      sessionId: sessionId,
                      onLeaveCall: () async {
                        await widget.onLeaveCall?.call(sessionId);
                      },
                      onSetMicrophoneMuted:
                          widget.onSetMicrophoneMuted != null &&
                              state.supportsInAppMicrophoneMute
                          ? ({required bool muted}) async {
                              await widget.onSetMicrophoneMuted!(
                                sessionId,
                                muted: muted,
                              );
                            }
                          : null,
                    ),
                  ),
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
        ],
        child: BlocBuilder<SessionDetailBloc, SessionDetailState>(
          builder: (context, state) => switch (state) {
            SessionDetailInitial() || SessionDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SessionDetailFailure(:final failure) => Center(
              child: Text(failure.toLocalizedMessage(context)),
            ),
            SessionDetailSuccess(:final aggregate, :final timeline) => ListView(
              padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
              children: [
                Text(
                  l10n.sessionStatusLabel(aggregate.lifecycleStatus.name),
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
                SizedBox(height: Theme.of(context).tokens.spaceExtraLarge),
                Text(
                  l10n.sessionTimelineTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: Theme.of(context).tokens.spaceSmall),
                if (timeline.isEmpty)
                  Text(l10n.sessionTimelineEmpty)
                else
                  ...timeline.map(
                    (event) => ListTile(
                      title: Text(event.action.name),
                      subtitle: Text(
                        event.reason ??
                            '${event.previousStatus.name} → ${event.newStatus.name}',
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
          },
        ),
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
