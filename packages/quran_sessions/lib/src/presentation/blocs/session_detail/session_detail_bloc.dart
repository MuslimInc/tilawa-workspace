import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/session_aggregate.dart';
import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/pending_reschedule_request.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/providers/auth_session_provider.dart';
import '../../../domain/usecases/cancel_session_via_server_usecase.dart';
import '../../../domain/usecases/get_session_aggregate_usecase.dart';
import '../../../domain/usecases/resolve_session_actor_role_usecase.dart';
import '../../../domain/usecases/get_pending_reschedule_request_usecase.dart';
import '../../../domain/usecases/get_session_timeline_usecase.dart';
import '../../../domain/usecases/join_session_usecase.dart';
import '../../../domain/usecases/open_session_dispute_usecase.dart';
import '../../../domain/usecases/report_session_concern_usecase.dart';
import '../../../domain/usecases/respond_to_reschedule_request_usecase.dart';
import '../../../domain/usecases/submit_review_usecase.dart';
import '../../../application/usecases/get_session_detail_usecase.dart';
import '../../../application/usecases/invalidate_quran_session_cache_usecase.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/policies/platform_scheduling_policy.dart';
import '../../../domain/policies/session_join_window_policy.dart';
import '../../../boundaries/call/call_token_provider.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

typedef OpenExternalMeetingUrl = Future<void> Function(String url);

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._getSessionAggregate,
    required this._getTimeline,
    GetSessionDetailUseCase? sessionDetailUseCase,
    InvalidateQuranSessionCacheUseCase? cacheInvalidator,
    this._sessionRepository,
    this._joinSession,
    this._openExternalMeetingUrl,
    this._reportConcern,
    this._openDispute,
    this._submitReview,
    this._getPendingReschedule,
    this._respondToReschedule,
    this._cancelSession,
    this._authSession,
    this._resolveActorRole,
    this._tokenProvider,
    this._joinWindowPolicy = const SessionJoinWindowPolicy(),
  }) : _getSessionDetail = sessionDetailUseCase,
       _invalidateCache = cacheInvalidator,
       super(const SessionDetailInitial()) {
    on<SessionDetailLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<SessionDetailJoinRequested>(
      _onJoinRequested,
      transformer: sequential(),
    );
    on<SessionDetailOpenMeetingAgainRequested>(
      _onOpenMeetingAgainRequested,
      transformer: sequential(),
    );
    on<SessionDetailReportSubmitted>(
      _onReportSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailReportAcknowledged>(
      _onReportAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailDisputeSubmitted>(
      _onDisputeSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailDisputeAcknowledged>(
      _onDisputeAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailRescheduleRespondSubmitted>(
      _onRescheduleRespondSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailRescheduleRespondAcknowledged>(
      _onRescheduleRespondAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailCancelSubmitted>(
      _onCancelSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailCancelAcknowledged>(
      _onCancelAcknowledged,
      transformer: sequential(),
    );
    on<SessionDetailReviewSubmitted>(
      _onReviewSubmitted,
      transformer: sequential(),
    );
    on<SessionDetailReviewAcknowledged>(
      _onReviewAcknowledged,
      transformer: sequential(),
    );
  }

  final GetSessionAggregateUseCase _getSessionAggregate;
  final GetSessionTimelineUseCase _getTimeline;
  final ResolveSessionActorRoleUseCase? _resolveActorRole;
  final GetSessionDetailUseCase? _getSessionDetail;
  final InvalidateQuranSessionCacheUseCase? _invalidateCache;
  final SessionRepository? _sessionRepository;
  final JoinSessionUseCase? _joinSession;
  final OpenExternalMeetingUrl? _openExternalMeetingUrl;
  final ReportSessionConcernUseCase? _reportConcern;
  final OpenSessionDisputeUseCase? _openDispute;
  final SubmitReviewUseCase? _submitReview;
  final GetPendingRescheduleRequestUseCase? _getPendingReschedule;
  final RespondToRescheduleRequestUseCase? _respondToReschedule;
  final CancelSessionViaServerUseCase? _cancelSession;
  final AuthSessionProvider? _authSession;
  final CallTokenProvider? _tokenProvider;
  final SessionJoinWindowPolicy _joinWindowPolicy;

  Future<void> _onLoadRequested(
    SessionDetailLoadRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());

    final aggregateResult = await _getSessionAggregate(event.bookingId);
    if (aggregateResult.isLeft()) {
      aggregateResult.fold(
        (f) => emit(SessionDetailFailure(f)),
        (_) {},
      );
      return;
    }

    final aggregate = aggregateResult.fold(
      (_) => throw StateError('noop'),
      (r) => r,
    );
    final timelineResult = await _getTimeline(
      bookingId: aggregate.id,
      sessionId: aggregate.sessionId,
    );
    // [UnauthorizedFailure] means no audit access — empty timeline, not an error.
    final timelineLoadFailed = timelineResult.fold(
      (failure) => failure is! UnauthorizedFailure,
      (_) => false,
    );
    final timeline = timelineResult.fold(
      (_) => const <SessionAuditEvent>[],
      (events) => events,
    );

    final callContext = await _loadSessionCallContext(
      sessionId: aggregate.sessionId,
    );

    final rescheduleContext = await _loadRescheduleContext(
      aggregate: aggregate,
    );

    final viewerRole = await _resolveActorRole?.forAggregate(aggregate);

    emit(
      SessionDetailSuccess(
        aggregate: aggregate,
        timeline: timeline,
        callType: callContext.callType,
        externalMeetingJoinUrl: callContext.externalMeetingJoinUrl,
        callProviderKind: callContext.callProviderKind,
        timelineLoadFailed: timelineLoadFailed,
        pendingRescheduleLoadFailed: rescheduleContext.loadFailed,
        pendingRescheduleRequest: rescheduleContext.request,
        canRespondToReschedule: rescheduleContext.canRespond,
        isAwaitingRescheduleCounterparty: rescheduleContext.isAwaiting,
        viewerRole: viewerRole,
      ),
    );

    _prefetchRtcCredentialsIfNeeded(
      aggregate: aggregate,
      callProviderKind: callContext.callProviderKind,
    );
  }

  void _prefetchRtcCredentialsIfNeeded({
    required SessionAggregate aggregate,
    required SessionCallProviderKind? callProviderKind,
  }) {
    final tokenProvider = _tokenProvider;
    final userId = _authSession?.currentUserId;
    final sessionId = aggregate.sessionId;
    if (tokenProvider == null ||
        userId == null ||
        userId.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return;
    }
    if (callProviderKind != SessionCallProviderKind.agora &&
        callProviderKind != SessionCallProviderKind.livekit) {
      return;
    }
    if (!aggregate.lifecycleStatus.canJoinSession) {
      return;
    }
    if (!_joinWindowPolicy.isWithinJoinWindow(
      startsAt: aggregate.startsAt,
      endsAt: aggregate.startsAt.add(
        const Duration(
          minutes: PlatformSchedulingPolicy.defaultSlotDurationMinutes,
        ),
      ),
      now: DateTime.now(),
    )) {
      return;
    }

    unawaited(
      tokenProvider.fetchCredentials(sessionId: sessionId, userId: userId),
    );
  }

  Future<
    ({
      PendingRescheduleRequest? request,
      bool canRespond,
      bool isAwaiting,
      bool loadFailed,
    })
  >
  _loadRescheduleContext({required SessionAggregate aggregate}) async {
    final getPending = _getPendingReschedule;
    if (getPending == null ||
        aggregate.lifecycleStatus != SessionLifecycleStatus.rescheduled) {
      return (
        request: null,
        canRespond: false,
        isAwaiting: false,
        loadFailed: false,
      );
    }

    final pendingResult = await getPending(aggregate.id);
    return pendingResult.fold(
      (failure) => (
        request: null,
        canRespond: false,
        isAwaiting: false,
        loadFailed: failure is! UnauthorizedFailure,
      ),
      (request) {
        if (request == null || !request.isPending) {
          return (
            request: null,
            canRespond: false,
            isAwaiting: false,
            loadFailed: false,
          );
        }

        final userId = _authSession?.currentUserId;
        if (userId == null || userId.isEmpty) {
          return (
            request: request,
            canRespond: false,
            isAwaiting: false,
            loadFailed: false,
          );
        }

        final isRequester = request.requestedByUserId == userId;
        return (
          request: request,
          canRespond: !isRequester,
          isAwaiting: isRequester,
          loadFailed: false,
        );
      },
    );
  }

  Future<
    ({
      SessionCallType? callType,
      String? externalMeetingJoinUrl,
      SessionCallProviderKind? callProviderKind,
    })
  >
  _loadSessionCallContext({required String? sessionId}) async {
    final repository = _sessionRepository;
    if (sessionId == null || sessionId.isEmpty) {
      return (
        callType: null,
        externalMeetingJoinUrl: null,
        callProviderKind: null,
      );
    }

    final sessionResult = _getSessionDetail != null
        ? await _getSessionDetail(sessionId)
        : await repository?.getSessionById(sessionId);
    if (sessionResult == null) {
      return (
        callType: null,
        externalMeetingJoinUrl: null,
        callProviderKind: null,
      );
    }
    return sessionResult.fold(
      (_) => (
        callType: null,
        externalMeetingJoinUrl: null,
        callProviderKind: null,
      ),
      (session) {
        String? externalMeetingJoinUrl;
        if (session.callType == SessionCallType.externalMeeting &&
            session.callProviderKind == SessionCallProviderKind.external) {
          final url = session.joinUrl?.trim();
          externalMeetingJoinUrl = (url?.isNotEmpty ?? false) ? url : null;
        }
        return (
          callType: session.callType,
          externalMeetingJoinUrl: externalMeetingJoinUrl,
          callProviderKind: session.callProviderKind,
        );
      },
    );
  }

  Future<void> _onJoinRequested(
    SessionDetailJoinRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final joinSession = _joinSession;
    final current = state;
    if (joinSession == null || current is! SessionDetailSuccess) return;

    final sessionId = current.aggregate.sessionId;
    if (sessionId == null ||
        !current.aggregate.lifecycleStatus.canJoinSession) {
      return;
    }

    emit(current.copyWith(joinInProgress: true, clearJoinFailure: true));

    final result = await joinSession(sessionId: sessionId);
    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          joinFailure: failure,
          clearJoinInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          clearJoinInProgress: true,
          hasOpenedExternalMeeting: after.isExternalMeeting,
        ),
      ),
    );
  }

  Future<void> _onOpenMeetingAgainRequested(
    SessionDetailOpenMeetingAgainRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final opener = _openExternalMeetingUrl;
    final current = state;
    if (opener == null || current is! SessionDetailSuccess) return;

    final url = current.externalMeetingJoinUrl;
    if (url == null || url.isEmpty) return;

    emit(current.copyWith(joinInProgress: true, clearJoinFailure: true));

    try {
      await opener(url);
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          clearJoinInProgress: true,
          hasOpenedExternalMeeting: true,
        ),
      );
    } on QuranSessionsFailure catch (failure) {
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          joinFailure: failure,
          clearJoinInProgress: true,
        ),
      );
    } on Object {
      final after = state;
      if (after is! SessionDetailSuccess) return;
      emit(
        after.copyWith(
          joinFailure: const ExternalMeetingLaunchFailure(),
          clearJoinInProgress: true,
        ),
      );
    }
  }

  Future<void> _onReportSubmitted(
    SessionDetailReportSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final useCase = _reportConcern;
    final current = state;
    if (useCase == null || current is! SessionDetailSuccess) return;

    emit(
      current.copyWith(
        reportInProgress: true,
        clearReportFailure: true,
        clearReportSubmitted: true,
      ),
    );

    final result = await useCase(
      category: event.category,
      description: event.description,
      bookingId: current.aggregate.id,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          reportFailure: failure,
          clearReportInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          reportSubmitted: true,
          clearReportInProgress: true,
        ),
      ),
    );
  }

  void _onReportAcknowledged(
    SessionDetailReportAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearReportSubmitted: true));
  }

  Future<void> _onDisputeSubmitted(
    SessionDetailDisputeSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final useCase = _openDispute;
    final current = state;
    if (useCase == null || current is! SessionDetailSuccess) return;

    emit(
      current.copyWith(
        disputeInProgress: true,
        clearDisputeFailure: true,
        clearDisputeSubmitted: true,
      ),
    );

    final result = await useCase(
      bookingId: current.aggregate.id,
      reason: event.reason,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          disputeFailure: failure,
          clearDisputeInProgress: true,
        ),
      ),
      (disputeId) => emit(
        after.copyWith(
          disputeSubmitted: true,
          clearDisputeInProgress: true,
          aggregate: after.aggregate.copyWith(
            lifecycleStatus: SessionLifecycleStatus.disputed,
          ),
        ),
      ),
    );

    final latest = state;
    if (result.isRight() && latest is SessionDetailSuccess) {
      _invalidateAggregateCaches(latest.aggregate);
    }
  }

  void _onDisputeAcknowledged(
    SessionDetailDisputeAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearDisputeSubmitted: true));
  }

  Future<void> _onRescheduleRespondSubmitted(
    SessionDetailRescheduleRespondSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final respond = _respondToReschedule;
    final current = state;
    if (respond == null || current is! SessionDetailSuccess) return;

    final request = current.pendingRescheduleRequest;
    if (request == null || !current.canRespondToReschedule) return;

    final actorRole = await _resolveActorRole?.forAggregate(current.aggregate);
    if (actorRole == null) {
      emit(
        current.copyWith(
          rescheduleRespondFailure: const UnauthorizedFailure(),
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        rescheduleRespondInProgress: true,
        clearRescheduleRespondFailure: true,
        clearRescheduleRespondAccepted: true,
      ),
    );

    final result = await respond(
      requestId: request.requestId,
      accept: event.accept,
      actorRole: actorRole,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    await result.fold(
      (failure) async {
        emit(
          after.copyWith(
            rescheduleRespondFailure: failure,
            clearRescheduleRespondInProgress: true,
          ),
        );
      },
      (aggregate) async {
        _invalidateAggregateCaches(aggregate);
        emit(
          after.copyWith(
            aggregate: aggregate,
            clearPendingRescheduleRequest: true,
            canRespondToReschedule: false,
            isAwaitingRescheduleCounterparty: false,
            rescheduleRespondAccepted: event.accept,
            clearRescheduleRespondInProgress: true,
          ),
        );
      },
    );
  }

  void _onRescheduleRespondAcknowledged(
    SessionDetailRescheduleRespondAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearRescheduleRespondAccepted: true));
  }

  Future<void> _onCancelSubmitted(
    SessionDetailCancelSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final cancelSession = _cancelSession;
    final current = state;
    if (cancelSession == null || current is! SessionDetailSuccess) return;
    if (!current.canCancel) return;

    final actorRole = current.viewerRole;
    if (actorRole == null ||
        actorRole == ActorRole.admin ||
        actorRole == ActorRole.system) {
      return;
    }

    final actorId = switch (actorRole) {
      ActorRole.student =>
        _authSession?.currentUserId ?? current.aggregate.studentId,
      ActorRole.teacher =>
        _authSession?.currentUserId ?? current.aggregate.teacherId,
      _ => '',
    };
    if (actorId.isEmpty) {
      emit(
        current.copyWith(cancellationFailure: const UnauthorizedFailure()),
      );
      return;
    }

    emit(
      current.copyWith(
        cancellationInProgress: true,
        clearCancellationFailure: true,
        clearCancellationSucceeded: true,
      ),
    );

    final result = await cancelSession(
      bookingId: current.aggregate.id,
      actorId: actorId,
      actorRole: actorRole,
      reason: event.reason,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    await result.fold(
      (failure) async {
        emit(
          after.copyWith(
            cancellationFailure: failure,
            clearCancellationInProgress: true,
          ),
        );
      },
      (aggregate) async {
        _invalidateAggregateCaches(aggregate);
        emit(
          after.copyWith(
            aggregate: aggregate,
            cancellationSucceeded: true,
            clearCancellationInProgress: true,
          ),
        );
      },
    );
  }

  void _onCancelAcknowledged(
    SessionDetailCancelAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearCancellationSucceeded: true));
  }

  Future<void> _onReviewSubmitted(
    SessionDetailReviewSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    final useCase = _submitReview;
    final current = state;
    if (useCase == null || current is! SessionDetailSuccess) return;
    if (!current.canReview) return;

    final sessionId = current.aggregate.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    emit(
      current.copyWith(
        reviewInProgress: true,
        clearReviewFailure: true,
        clearReviewSubmitted: true,
      ),
    );

    final result = await useCase(
      sessionId: sessionId,
      rating: event.rating,
      comment: event.comment,
    );

    final after = state;
    if (after is! SessionDetailSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          reviewFailure: failure,
          clearReviewInProgress: true,
        ),
      ),
      (_) => emit(
        after.copyWith(
          reviewSubmitted: true,
          reviewCompleted: true,
          clearReviewInProgress: true,
        ),
      ),
    );
  }

  void _onReviewAcknowledged(
    SessionDetailReviewAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearReviewSubmitted: true));
  }

  void _invalidateAggregateCaches(SessionAggregate aggregate) {
    final sessionId = aggregate.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    _invalidateCache?.invalidateSession(
      sessionId,
      teacherProfileId: aggregate.teacherId,
      studentId: aggregate.studentId,
    );
  }
}
