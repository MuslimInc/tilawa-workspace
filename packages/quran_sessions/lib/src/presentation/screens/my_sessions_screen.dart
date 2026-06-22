import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({
    super.key,
    required this.studentId,
    this.resolveTeacherName,
    this.onRescheduleRequested,
    this.onSessionDetailRequested,
  });

  final String studentId;

  final String? Function(String teacherId)? resolveTeacherName;

  final void Function({
    required String bookingId,
    required String teacherId,
    required String studentId,
  })?
  onRescheduleRequested;

  final void Function(String bookingId)? onSessionDetailRequested;

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MySessionsBloc>().add(
      MySessionsLoadRequested(studentId: widget.studentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mySessionsTitle)),
      body: BlocConsumer<MySessionsBloc, MySessionsState>(
        listener: (context, state) {
          if (state is MySessionsSuccess && state.lastSubmittedReview != null) {
            TilawaFeedback.showToast(
              context,
              message: l10n.reviewSubmittedThanks,
              variant: TilawaFeedbackVariant.success,
            );
          }
          if (state is MySessionsSuccess && state.cancellationFailure != null) {
            TilawaFeedback.showToast(
              context,
              message: state.cancellationFailure!.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
          }
        },
        builder: (context, state) => switch (state) {
          MySessionsInitial() || MySessionsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MySessionsEmpty() => const Center(
            child: _EmptyState(),
          ),
          MySessionsFailure(:final failure) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.toLocalizedMessage(context)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reload,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          MySessionsSuccess(:final upcoming, :final past) => RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                _SectionHeader(
                  title: l10n.upcomingSessionsSection(upcoming.length),
                ),
                if (upcoming.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noUpcomingSessions),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) {
                      final session = upcoming[i];
                      return Column(
                        children: [
                          SessionCard(
                            session: session,
                            teacherName: widget.resolveTeacherName?.call(
                              session.teacherId,
                            ),
                            onJoin: () => context.read<MySessionsBloc>().add(
                              SessionJoinRequested(sessionId: session.id),
                            ),
                            onCancel: () => _confirmCancel(session),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    widget.onSessionDetailRequested?.call(
                                      session.bookingId,
                                    ),
                                child: Text(l10n.viewSessionDetails),
                              ),
                              if (widget.onRescheduleRequested != null)
                                TextButton(
                                  onPressed: () =>
                                      widget.onRescheduleRequested!(
                                        bookingId: session.bookingId,
                                        teacherId: session.teacherId,
                                        studentId: widget.studentId,
                                      ),
                                  child: Text(l10n.rescheduleAction),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                _SectionHeader(title: l10n.pastSessionsSection(past.length)),
                if (past.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noPastSessions),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: past.length,
                    itemBuilder: (context, i) {
                      final session = past[i];
                      return SessionCard(
                        session: session,
                        teacherName: widget.resolveTeacherName?.call(
                          session.teacherId,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        },
      ),
    );
  }

  void _reload() => context.read<MySessionsBloc>().add(
    MySessionsLoadRequested(studentId: widget.studentId),
  );

  Future<void> _confirmCancel(QuranSession session) async {
    final reason = await showCancelSessionSheet(
      context,
      sessionStartsAt: session.startsAt,
      pricingType: SessionPricingType.free,
    );
    if (reason != null && mounted) {
      context.read<MySessionsBloc>().add(
        SessionCancelled(bookingId: session.bookingId, reason: reason),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSessionsYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookFirstSessionHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
