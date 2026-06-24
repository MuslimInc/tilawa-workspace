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
    this.createCallControlGateway,
    this.createCallTelemetry,
    this.buildCallSurface,
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

  final SessionCallControlGatewayFactory? createCallControlGateway;
  final CallTelemetryCoordinatorFactory? createCallTelemetry;
  final InAppCallSurfaceBuilder? buildCallSurface;

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
      body: MultiBlocListener(
        listeners: [
          BlocListener<MySessionsBloc, MySessionsState>(
            listenWhen: (previous, current) =>
                current is MySessionsSuccess &&
                current.joinCompletedSessionId != null &&
                (previous is! MySessionsSuccess ||
                    previous.joinCompletedSessionId !=
                        current.joinCompletedSessionId),
            listener: (context, state) async {
              if (state is! MySessionsSuccess) return;

              final sessionId = state.joinCompletedSessionId;
              if (sessionId == null) return;

              final session = _findSession(state, sessionId);
              context.read<MySessionsBloc>().add(
                const MySessionsJoinCompletedAcknowledged(),
              );

              if (session == null || _isExternalMeeting(session)) {
                return;
              }

              if (!context.mounted) return;
              await pushInAppCallShell(
                context,
                sessionId: sessionId,
                callType: session.callType,
                callProviderKind: session.callProviderKind,
                participantName: widget.resolveTeacherName?.call(
                  session.teacherId,
                ),
                participantSubtitle: l10n.callTypeLabel(session.callType),
                buildCallSurface: widget.buildCallSurface,
                createCallControlGateway: widget.createCallControlGateway,
                createCallTelemetry: widget.createCallTelemetry,
              );
            },
          ),
          BlocListener<MySessionsBloc, MySessionsState>(
            listener: (context, state) {
              if (state is MySessionsSuccess &&
                  state.lastSubmittedReview != null) {
                TilawaFeedback.showToast(
                  context,
                  message: l10n.reviewSubmittedThanks,
                  variant: TilawaFeedbackVariant.success,
                );
              }
              if (state is MySessionsSuccess &&
                  state.cancellationFailure != null) {
                TilawaFeedback.showToast(
                  context,
                  message: state.cancellationFailure!.toLocalizedMessage(
                    context,
                  ),
                  variant: TilawaFeedbackVariant.error,
                );
              }
              if (state is MySessionsSuccess && state.joinFailure != null) {
                TilawaFeedback.showToast(
                  context,
                  message: state.joinFailure!.toLocalizedMessage(context),
                  variant: TilawaFeedbackVariant.error,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<MySessionsBloc, MySessionsState>(
          builder: (context, state) => switch (state) {
            MySessionsInitial() || MySessionsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            MySessionsEmpty() => const Center(
              child: _EmptyState(),
            ),
            MySessionsFailure(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(
                  Theme.of(context).tokens.spaceLarge,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.toLocalizedMessage(context)),
                    SizedBox(height: Theme.of(context).tokens.spaceMedium),
                    TilawaButton(
                      text: l10n.retry,
                      variant: TilawaButtonVariant.primary,
                      onPressed: _reload,
                    ),
                  ],
                ),
              ),
            ),
            final MySessionsSuccess success => RefreshIndicator(
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  _SectionHeader(
                    title: l10n.upcomingSessionsSection(
                      success.upcoming.length,
                    ),
                  ),
                  if (success.upcoming.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(
                          Theme.of(context).tokens.spaceLarge,
                        ),
                        child: Text(l10n.noUpcomingSessions),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: success.upcoming.length,
                      itemBuilder: (context, i) {
                        final session = success.upcoming[i];
                        return Column(
                          children: [
                            SessionCard(
                              session: session,
                              teacherName: widget.resolveTeacherName?.call(
                                session.teacherId,
                              ),
                              isJoinLoading:
                                  success.joinInProgress == session.id,
                              onJoin: () => _requestJoin(session),
                              onCancel: () => _confirmCancel(session),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TilawaButton(
                                  text: l10n.viewSessionDetails,
                                  variant: TilawaButtonVariant.ghost,
                                  size: TilawaButtonSize.small,
                                  onPressed: () =>
                                      widget.onSessionDetailRequested?.call(
                                        session.bookingId,
                                      ),
                                ),
                                if (widget.onRescheduleRequested != null)
                                  TilawaButton(
                                    text: l10n.rescheduleAction,
                                    variant: TilawaButtonVariant.ghost,
                                    size: TilawaButtonSize.small,
                                    onPressed: () =>
                                        widget.onRescheduleRequested!(
                                          bookingId: session.bookingId,
                                          teacherId: session.teacherId,
                                          studentId: widget.studentId,
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  _SectionHeader(
                    title: l10n.pastSessionsSection(success.past.length),
                  ),
                  if (success.past.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(
                          Theme.of(context).tokens.spaceLarge,
                        ),
                        child: Text(l10n.noPastSessions),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: success.past.length,
                      itemBuilder: (context, i) {
                        final session = success.past[i];
                        return SessionCard(
                          session: session,
                          teacherName: widget.resolveTeacherName?.call(
                            session.teacherId,
                          ),
                        );
                      },
                    ),
                  if (success.pastNextCursor != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(
                          Theme.of(context).tokens.spaceLarge,
                        ),
                        child: TilawaButton(
                          text: l10n.loadMorePastSessions,
                          variant: TilawaButtonVariant.secondary,
                          isLoading: success.isLoadingMorePast,
                          onPressed: success.isLoadingMorePast
                              ? null
                              : () => context.read<MySessionsBloc>().add(
                                  MySessionsLoadMorePastRequested(
                                    studentId: widget.studentId,
                                  ),
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

  QuranSession? _findSession(MySessionsSuccess state, String sessionId) {
    for (final session in state.upcoming) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  bool _isExternalMeeting(QuranSession session) {
    if (session.callProviderKind != SessionCallProviderKind.external) {
      return false;
    }
    final url = session.joinUrl?.trim();
    return url?.isNotEmpty ?? false;
  }

  Future<void> _requestJoin(QuranSession session) async {
    if (_isExternalMeeting(session)) {
      final confirmed = await showExternalMeetingJoinSheet(
        context,
        meetingUrl: session.joinUrl!,
      );
      if (!confirmed || !mounted) return;
    }
    context.read<MySessionsBloc>().add(
      SessionJoinRequested(sessionId: session.id),
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
    final tokens = Theme.of(context).tokens;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceSection,
          tokens.spaceLarge,
          tokens.spaceSmall,
        ),
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
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceXXL),
      child: TilawaIllustratedState(
        title: l10n.noSessionsYet,
        subtitle: l10n.bookFirstSessionHint,
        icon: Icons.menu_book_outlined,
        iconColor: scheme.outlineVariant,
      ),
    );
  }
}
