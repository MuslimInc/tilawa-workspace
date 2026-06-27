import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../layout/quran_sessions_scroll_padding.dart';

enum _MySessionsTab { upcoming, past, cancelled }

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({
    super.key,
    required this.studentId,
    this.resolveTeacherName,
    this.scrollBottomPadding,
    this.onRescheduleRequested,
    this.onSessionDetailRequested,
    this.onBookAgainRequested,
    this.createCallControlGateway,
    this.createCallTelemetry,
    this.buildCallSurface,
  });

  final String studentId;

  final String? Function(String teacherId)? resolveTeacherName;

  /// Host-provided bottom inset (mini-player, shell tabs). Falls back to
  /// [quranSessionsDefaultScrollBottomPadding].
  final QuranSessionsScrollBottomPaddingBuilder? scrollBottomPadding;

  final void Function({
    required String bookingId,
    required String teacherId,
    required String studentId,
  })?
  onRescheduleRequested;

  final void Function(String bookingId)? onSessionDetailRequested;

  final void Function(String teacherId)? onBookAgainRequested;

  final SessionCallControlGatewayFactory? createCallControlGateway;
  final CallTelemetryCoordinatorFactory? createCallTelemetry;
  final InAppCallSurfaceBuilder? buildCallSurface;

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  _MySessionsTab _selectedTab = _MySessionsTab.upcoming;
  final Set<String> _reviewedSessionIds = {};
  final Set<String> _autoPromptedReviewSessionIds = {};

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

    return QuranSessionsScaffold(
      title: l10n.mySessionsTitle,
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
                setState(() {
                  _reviewedSessionIds.add(state.lastSubmittedReview!.sessionId);
                });
                TilawaFeedback.showToast(
                  context,
                  message: l10n.reviewSubmittedThanks,
                  variant: TilawaFeedbackVariant.success,
                );
              }
              if (state is MySessionsSuccess && state.reviewFailure != null) {
                TilawaFeedback.showToast(
                  context,
                  message: state.reviewFailure!.toLocalizedMessage(context),
                  variant: TilawaFeedbackVariant.error,
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
            final MySessionsSuccess success => _SuccessBody(
              success: success,
              selectedTab: _selectedTab,
              onTabChanged: _onTabChanged,
              studentId: widget.studentId,
              scrollBottomPadding: widget.scrollBottomPadding,
              resolveTeacherName: widget.resolveTeacherName,
              onRescheduleRequested: widget.onRescheduleRequested,
              onSessionDetailRequested: widget.onSessionDetailRequested,
              onBookAgainRequested: widget.onBookAgainRequested,
              onJoin: _requestJoin,
              onCancel: _confirmCancel,
              onReload: _reload,
              onReview: _promptReview,
              canReviewSession: _canReviewSession,
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

  void _onTabChanged(_MySessionsTab tab) {
    setState(() => _selectedTab = tab);
    if (tab != _MySessionsTab.past) return;

    final state = context.read<MySessionsBloc>().state;
    if (state is! MySessionsSuccess) return;

    final session = _firstReviewablePastSession(state);
    if (session != null) {
      unawaited(_maybeAutoPromptReview(session));
    }
  }

  bool _canReviewSession(QuranSession session) {
    if (!isSessionEligibleForStudentReview(session)) return false;
    if (_reviewedSessionIds.contains(session.id)) return false;
    final submitted = context.read<MySessionsBloc>().state;
    if (submitted is MySessionsSuccess &&
        submitted.lastSubmittedReview?.sessionId == session.id) {
      return false;
    }
    return true;
  }

  QuranSession? _firstReviewablePastSession(MySessionsSuccess success) {
    for (final session in success.past) {
      if (_isCancelledSession(session)) continue;
      if (_canReviewSession(session)) return session;
    }
    return null;
  }

  Future<void> _maybeAutoPromptReview(QuranSession session) async {
    if (_autoPromptedReviewSessionIds.contains(session.id)) return;
    _autoPromptedReviewSessionIds.add(session.id);
    await _promptReview(session);
  }

  Future<void> _promptReview(QuranSession session) async {
    if (!_canReviewSession(session) || !mounted) return;

    final input = await showSessionReviewSheet(
      context,
      teacherName: widget.resolveTeacherName?.call(session.teacherId),
    );
    if (input == null || !mounted) return;

    context.read<MySessionsBloc>().add(
      ReviewSubmitted(
        sessionId: session.id,
        rating: input.rating,
        comment: input.comment,
      ),
    );
  }

  bool _isCancelledSession(QuranSession session) {
    if (session.effectiveLifecycleStatus.isCancelled) return true;
    return switch (session.status) {
      QuranSessionStatus.cancelledByStudent ||
      QuranSessionStatus.cancelledByTeacher => true,
      _ => false,
    };
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.success,
    required this.selectedTab,
    required this.onTabChanged,
    required this.studentId,
    this.scrollBottomPadding,
    required this.resolveTeacherName,
    required this.onRescheduleRequested,
    required this.onSessionDetailRequested,
    required this.onBookAgainRequested,
    required this.onJoin,
    required this.onCancel,
    required this.onReload,
    required this.onReview,
    required this.canReviewSession,
  });

  final MySessionsSuccess success;
  final _MySessionsTab selectedTab;
  final ValueChanged<_MySessionsTab> onTabChanged;
  final String studentId;
  final QuranSessionsScrollBottomPaddingBuilder? scrollBottomPadding;
  final String? Function(String teacherId)? resolveTeacherName;
  final void Function({
    required String bookingId,
    required String teacherId,
    required String studentId,
  })?
  onRescheduleRequested;
  final void Function(String bookingId)? onSessionDetailRequested;
  final void Function(String teacherId)? onBookAgainRequested;
  final Future<void> Function(QuranSession session) onJoin;
  final Future<void> Function(QuranSession session) onCancel;
  final VoidCallback onReload;
  final Future<void> Function(QuranSession session) onReview;
  final bool Function(QuranSession session) canReviewSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final now = DateTime.now();
    final bottomPadding =
        (scrollBottomPadding ?? quranSessionsDefaultScrollBottomPadding)(
          context,
        );
    final cancelled = _cancelledSessions(success);
    final sessions = switch (selectedTab) {
      _MySessionsTab.upcoming => success.upcoming,
      _MySessionsTab.past =>
        success.past.where((session) => !_isCancelledSession(session)).toList(),
      _MySessionsTab.cancelled => cancelled,
    };

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: QuranSessionSummaryStrip(
              upcomingCount: success.upcoming.length,
              pastCount: success.past.length,
              nextUpcoming: success.upcoming.isEmpty
                  ? null
                  : success.upcoming.first,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: TilawaSegmentedControl<_MySessionsTab>(
                selectedValue: selectedTab,
                onValueChanged: onTabChanged,
                segments: [
                  TilawaSegment(
                    value: _MySessionsTab.upcoming,
                    label: l10n.sessionsTabUpcoming,
                  ),
                  TilawaSegment(
                    value: _MySessionsTab.past,
                    label: l10n.sessionsTabPast,
                  ),
                  TilawaSegment(
                    value: _MySessionsTab.cancelled,
                    label: l10n.sessionsTabCancelled,
                  ),
                ],
              ),
            ),
          ),
          if (sessions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLarge),
                child: Text(
                  switch (selectedTab) {
                    _MySessionsTab.upcoming => l10n.noUpcomingSessions,
                    _MySessionsTab.past => l10n.noPastSessions,
                    _MySessionsTab.cancelled => l10n.sessionStatusCancelled,
                  },
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isUpcomingTab = selectedTab == _MySessionsTab.upcoming;
                return QuranSessionCard(
                  session: session,
                  now: now,
                  highlighted: isUpcomingTab && index == 0,
                  teacherName: resolveTeacherName?.call(session.teacherId),
                  variant: isUpcomingTab
                      ? QuranSessionCardVariant.upcoming
                      : QuranSessionCardVariant.past,
                  isJoinLoading: success.joinInProgress == session.id,
                  onJoin:
                      isUpcomingTab &&
                          session.effectiveLifecycleStatus.canJoinSession
                      ? () => onJoin(session)
                      : null,
                  onViewDetails: onSessionDetailRequested == null
                      ? null
                      : () => onSessionDetailRequested!(session.bookingId),
                  onReschedule:
                      isUpcomingTab &&
                          onRescheduleRequested != null &&
                          _canStudentRequestReschedule(session, now)
                      ? () => onRescheduleRequested!(
                          bookingId: session.bookingId,
                          teacherId: session.teacherId,
                          studentId: studentId,
                        )
                      : null,
                  onCancel:
                      isUpcomingTab && canStudentCancelQuranSession(session)
                      ? () => onCancel(session)
                      : null,
                  onBookAgain:
                      !isUpcomingTab &&
                          selectedTab == _MySessionsTab.past &&
                          onBookAgainRequested != null
                      ? () => onBookAgainRequested!(session.teacherId)
                      : null,
                  onReview:
                      !isUpcomingTab &&
                          selectedTab == _MySessionsTab.past &&
                          canReviewSession(session)
                      ? () => onReview(session)
                      : null,
                );
              },
            ),
          if (selectedTab == _MySessionsTab.past &&
              success.pastNextCursor != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLarge),
                child: TilawaButton(
                  text: l10n.loadMorePastSessions,
                  variant: TilawaButtonVariant.secondary,
                  isLoading: success.isLoadingMorePast,
                  onPressed: success.isLoadingMorePast
                      ? null
                      : () => context.read<MySessionsBloc>().add(
                          MySessionsLoadMorePastRequested(
                            studentId: studentId,
                          ),
                        ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  List<QuranSession> _cancelledSessions(MySessionsSuccess success) {
    return [
      ...success.upcoming.where(_isCancelledSession),
      ...success.past.where(_isCancelledSession),
    ];
  }

  bool _isCancelledSession(QuranSession session) {
    if (session.effectiveLifecycleStatus.isCancelled) return true;
    return switch (session.status) {
      QuranSessionStatus.cancelledByStudent ||
      QuranSessionStatus.cancelledByTeacher => true,
      _ => false,
    };
  }

  bool _canStudentRequestReschedule(QuranSession session, DateTime now) {
    if (session.effectiveLifecycleStatus.phase !=
        SessionLifecyclePhase.active) {
      return false;
    }
    if (!session.startsAt.isAfter(now)) {
      return false;
    }
    return session.startsAt.difference(now) >= const Duration(hours: 24);
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
