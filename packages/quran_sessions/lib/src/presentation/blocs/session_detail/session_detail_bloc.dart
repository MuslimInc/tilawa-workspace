import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/session_call_type.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/usecases/get_session_timeline_usecase.dart';
import '../../../domain/usecases/join_session_usecase.dart';
import '../../../domain/usecases/open_session_dispute_usecase.dart';
import '../../../domain/usecases/report_session_concern_usecase.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/repositories/session_aggregate_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

typedef OpenExternalMeetingUrl = Future<void> Function(String url);

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required SessionAggregateRepository aggregateRepository,
    required GetSessionTimelineUseCase getTimeline,
    SessionRepository? sessionRepository,
    JoinSessionUseCase? joinSession,
    OpenExternalMeetingUrl? openExternalMeetingUrl,
    ReportSessionConcernUseCase? reportConcern,
    OpenSessionDisputeUseCase? openDispute,
  }) : _aggregateRepository = aggregateRepository,
       _getTimeline = getTimeline,
       _sessionRepository = sessionRepository,
       _joinSession = joinSession,
       _openExternalMeetingUrl = openExternalMeetingUrl,
       _reportConcern = reportConcern,
       _openDispute = openDispute,
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
  }

  final SessionAggregateRepository _aggregateRepository;
  final GetSessionTimelineUseCase _getTimeline;
  final SessionRepository? _sessionRepository;
  final JoinSessionUseCase? _joinSession;
  final OpenExternalMeetingUrl? _openExternalMeetingUrl;
  final ReportSessionConcernUseCase? _reportConcern;
  final OpenSessionDisputeUseCase? _openDispute;

  Future<void> _onLoadRequested(
    SessionDetailLoadRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());

    final aggregateResult = await _aggregateRepository.getById(event.bookingId);
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
    final timelineId = aggregate.sessionId ?? aggregate.id;
    final timelineResult = await _getTimeline(timelineId);
    final timeline = timelineResult.fold(
      (_) => const <SessionAuditEvent>[],
      (events) => events,
    );

    final externalMeetingJoinUrl = await _loadExternalMeetingJoinUrl(
      sessionId: aggregate.sessionId,
    );

    emit(
      SessionDetailSuccess(
        aggregate: aggregate,
        timeline: timeline,
        externalMeetingJoinUrl: externalMeetingJoinUrl,
      ),
    );
  }

  Future<String?> _loadExternalMeetingJoinUrl({required String? sessionId}) async {
    final repository = _sessionRepository;
    if (repository == null || sessionId == null || sessionId.isEmpty) {
      return null;
    }

    final sessionResult = await repository.getSessionById(sessionId);
    return sessionResult.fold(
      (_) => null,
      (session) {
        if (session.callType != SessionCallType.externalMeeting ||
            session.callProviderKind != SessionCallProviderKind.external) {
          return null;
        }
        final url = session.joinUrl?.trim();
        return (url?.isNotEmpty ?? false) ? url : null;
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
  }

  void _onDisputeAcknowledged(
    SessionDetailDisputeAcknowledged event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailSuccess) return;
    emit(current.copyWith(clearDisputeSubmitted: true));
  }
}
