import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/call/call_provider.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/repositories/session_aggregate_repository.dart';
import '../../../domain/usecases/get_session_timeline_usecase.dart';
import '../../../domain/usecases/open_session_dispute_usecase.dart';
import '../../../domain/usecases/report_session_concern_usecase.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._aggregateRepository,
    required this._getTimeline,
    this._callProvider,
    this._reportConcern,
    this._openDispute,
  }) : super(const SessionDetailInitial()) {
    on<SessionDetailLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<SessionDetailJoinRequested>(
      _onJoinRequested,
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
  final CallProvider? _callProvider;
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
    final timelineResult = await _getTimeline(event.bookingId);
    timelineResult.fold(
      (failure) => emit(SessionDetailFailure(failure)),
      (timeline) => emit(
        SessionDetailSuccess(aggregate: aggregate, timeline: timeline),
      ),
    );
  }

  Future<void> _onJoinRequested(
    SessionDetailJoinRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    final provider = _callProvider;
    final current = state;
    if (provider == null || current is! SessionDetailSuccess) return;

    final sessionId = current.aggregate.sessionId;
    if (sessionId == null ||
        !current.aggregate.lifecycleStatus.canJoinSession) {
      return;
    }

    emit(current.copyWith(joinInProgress: true, clearJoinFailure: true));

    try {
      await provider.joinSession(sessionId);
      final after = state;
      if (after is SessionDetailSuccess) {
        emit(after.copyWith(clearJoinInProgress: true));
      }
    } on Object catch (_) {
      final after = state;
      if (after is SessionDetailSuccess) {
        emit(
          after.copyWith(
            joinFailure: const NetworkFailure(),
            clearJoinInProgress: true,
          ),
        );
      }
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
