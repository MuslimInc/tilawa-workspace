import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/call/call_provider.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/usecases/cancel_session_via_server_usecase.dart';
import '../../../domain/usecases/get_student_sessions_usecase.dart';
import '../../../domain/usecases/submit_review_usecase.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'my_sessions_event.dart';
import 'my_sessions_state.dart';

class MySessionsBloc extends Bloc<MySessionsEvent, MySessionsState> {
  MySessionsBloc({
    required this._getStudentSessions,
    required this._cancelSession,
    required this._submitReview,
    required this._callProvider,
    required this._studentId,
  }) : super(const MySessionsInitial()) {
    on<MySessionsLoadRequested>(_onLoadRequested, transformer: restartable());
    on<SessionCancelled>(_onSessionCancelled, transformer: sequential());
    on<SessionJoinRequested>(_onJoinRequested, transformer: sequential());
    on<ReviewSubmitted>(_onReviewSubmitted, transformer: droppable());
  }

  final GetStudentSessionsUseCase _getStudentSessions;
  final CancelSessionViaServerUseCase _cancelSession;
  final SubmitReviewUseCase _submitReview;
  final CallProvider _callProvider;
  final String _studentId;

  Future<void> _onLoadRequested(
    MySessionsLoadRequested event,
    Emitter<MySessionsState> emit,
  ) async {
    emit(const MySessionsLoading());

    final result = await _getStudentSessions(event.studentId);

    result.fold(
      (failure) => emit(MySessionsFailure(failure)),
      (sessions) {
        if (sessions.isEmpty) {
          emit(const MySessionsEmpty());
          return;
        }
        final now = DateTime.now();
        emit(
          MySessionsSuccess(
            upcoming: sessions.where((s) => s.startsAt.isAfter(now)).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
            past: sessions.where((s) => !s.startsAt.isAfter(now)).toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
          ),
        );
      },
    );
  }

  Future<void> _onSessionCancelled(
    SessionCancelled event,
    Emitter<MySessionsState> emit,
  ) async {
    final current = state;
    if (current is! MySessionsSuccess) return;

    emit(current.copyWith(cancellationInProgress: event.bookingId));

    final result = await _cancelSession(
      bookingId: event.bookingId,
      actorId: _studentId,
      actorRole: ActorRole.student,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(
        current
            .copyWith(
              clearCancellationFailure: true,
              cancellationFailure: failure,
            )
            .clearCancellation(),
      ),
      (_) {
        emit(
          current
              .copyWith(
                upcoming: current.upcoming
                    .where((s) => s.bookingId != event.bookingId)
                    .toList(),
              )
              .clearCancellation(),
        );
      },
    );
  }

  Future<void> _onJoinRequested(
    SessionJoinRequested event,
    Emitter<MySessionsState> emit,
  ) async {
    final current = state;
    if (current is! MySessionsSuccess) return;

    emit(
      current.copyWith(clearJoinFailure: true, joinInProgress: event.sessionId),
    );

    try {
      await _callProvider.joinSession(event.sessionId);
      emit((state as MySessionsSuccess).clearJoin());
    } on Object catch (_) {
      final after = state;
      if (after is MySessionsSuccess) {
        emit(
          after
              .copyWith(
                joinFailure: const NetworkFailure(),
                clearJoinInProgress: true,
              )
              .clearJoin(),
        );
      }
    }
  }

  Future<void> _onReviewSubmitted(
    ReviewSubmitted event,
    Emitter<MySessionsState> emit,
  ) async {
    final current = state;
    if (current is! MySessionsSuccess) return;

    final result = await _submitReview(
      sessionId: event.sessionId,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (_) => null,
      (review) => emit(current.copyWith(lastSubmittedReview: review)),
    );
  }
}
