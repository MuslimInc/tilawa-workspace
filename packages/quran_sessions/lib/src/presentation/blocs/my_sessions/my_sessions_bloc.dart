import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/cancel_session_via_server_usecase.dart';
import '../../../domain/usecases/get_student_sessions_usecase.dart';
import '../../../domain/usecases/join_session_usecase.dart';
import '../../../domain/usecases/submit_review_usecase.dart';
import '../../../domain/value_objects/actor_role.dart';
import 'my_sessions_event.dart';
import 'my_sessions_state.dart';

class MySessionsBloc extends Bloc<MySessionsEvent, MySessionsState> {
  MySessionsBloc({
    required this._getStudentSessions,
    required this._cancelSession,
    required this._submitReview,
    required this._joinSession,
    required this._studentId,
  }) : super(const MySessionsInitial()) {
    on<MySessionsLoadRequested>(_onLoadRequested, transformer: restartable());
    on<MySessionsLoadMorePastRequested>(
      _onLoadMorePast,
      transformer: droppable(),
    );
    on<SessionCancelled>(_onSessionCancelled, transformer: sequential());
    on<SessionJoinRequested>(_onJoinRequested, transformer: sequential());
    on<MySessionsJoinCompletedAcknowledged>(
      _onJoinCompletedAcknowledged,
      transformer: sequential(),
    );
    on<ReviewSubmitted>(_onReviewSubmitted, transformer: droppable());
  }

  final GetStudentSessionsUseCase _getStudentSessions;
  final CancelSessionViaServerUseCase _cancelSession;
  final SubmitReviewUseCase _submitReview;
  final JoinSessionUseCase _joinSession;
  final String _studentId;

  Future<void> _onLoadRequested(
    MySessionsLoadRequested event,
    Emitter<MySessionsState> emit,
  ) async {
    emit(const MySessionsLoading());

    final result = await _getStudentSessions(event.studentId);

    result.fold(
      (failure) => emit(MySessionsFailure(failure)),
      (page) {
        if (page.upcoming.isEmpty && page.past.isEmpty) {
          emit(const MySessionsEmpty());
          return;
        }
        emit(
          MySessionsSuccess(
            upcoming: page.upcoming,
            past: page.past,
            pastNextCursor: page.pastNextCursor,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMorePast(
    MySessionsLoadMorePastRequested event,
    Emitter<MySessionsState> emit,
  ) async {
    final current = state;
    if (current is! MySessionsSuccess ||
        current.pastNextCursor == null ||
        current.isLoadingMorePast) {
      return;
    }

    emit(current.copyWith(isLoadingMorePast: true));

    final result = await _getStudentSessions(
      event.studentId,
      pastCursor: current.pastNextCursor,
    );

    final after = state;
    if (after is! MySessionsSuccess) return;

    result.fold(
      (failure) => emit(
        after.copyWith(
          isLoadingMorePast: false,
          loadMorePastFailure: failure,
        ),
      ),
      (page) {
        emit(
          after.copyWith(
            past: [...after.past, ...page.past],
            pastNextCursor: page.pastNextCursor,
            isLoadingMorePast: false,
            clearLoadMorePastFailure: true,
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

    final result = await _joinSession(sessionId: event.sessionId);

    final after = state;
    if (after is! MySessionsSuccess) return;

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
          joinCompletedSessionId: event.sessionId,
        ),
      ),
    );
  }

  Future<void> _onJoinCompletedAcknowledged(
    MySessionsJoinCompletedAcknowledged event,
    Emitter<MySessionsState> emit,
  ) async {
    final current = state;
    if (current is! MySessionsSuccess) return;

    emit(current.copyWith(clearJoinCompletedSessionId: true));
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
      (failure) => emit(current.copyWith(reviewFailure: failure)),
      (review) => emit(
        current.copyWith(
          lastSubmittedReview: review,
          clearReviewFailure: true,
        ),
      ),
    );
  }
}
