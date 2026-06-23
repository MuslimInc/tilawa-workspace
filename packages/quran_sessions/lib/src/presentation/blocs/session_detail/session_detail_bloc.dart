import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/call/call_provider.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/repositories/session_aggregate_repository.dart';
import '../../../domain/usecases/get_session_timeline_usecase.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required this._aggregateRepository,
    required this._getTimeline,
    this._callProvider,
  }) : super(const SessionDetailInitial()) {
    on<SessionDetailLoadRequested>(
      _onLoadRequested,
      transformer: restartable(),
    );
    on<SessionDetailJoinRequested>(
      _onJoinRequested,
      transformer: sequential(),
    );
  }

  final SessionAggregateRepository _aggregateRepository;
  final GetSessionTimelineUseCase _getTimeline;
  final CallProvider? _callProvider;

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
}
