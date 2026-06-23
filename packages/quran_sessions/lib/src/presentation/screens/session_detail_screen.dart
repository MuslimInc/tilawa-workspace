import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.bookingId});

  final String bookingId;

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
      body: BlocConsumer<SessionDetailBloc, SessionDetailState>(
        listener: (context, state) {
          if (state is SessionDetailSuccess && state.joinFailure != null) {
            TilawaFeedback.showToast(
              context,
              message: state.joinFailure!.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
          }
          if (state is SessionDetailSuccess && state.reportFailure != null) {
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
        },
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
            :final canJoin,
            :final joinInProgress,
          ) =>
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.sessionStatusLabel(aggregate.lifecycleStatus.name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sessionStartsAtLabel(
                    MaterialLocalizations.of(
                      context,
                    ).formatFullDate(aggregate.startsAt.toLocal()),
                  ),
                ),
                if (canJoin) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: joinInProgress
                        ? null
                        : () => context.read<SessionDetailBloc>().add(
                            const SessionDetailJoinRequested(),
                          ),
                    child: joinInProgress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.joinSession),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _submitReport(context),
                  child: Text(l10n.reportConcernAction),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.sessionTimelineTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
    );
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
}
