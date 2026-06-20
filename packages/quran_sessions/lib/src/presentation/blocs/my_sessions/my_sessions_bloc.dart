import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/cancel_booking_usecase.dart';
import '../../../domain/usecases/get_student_sessions_usecase.dart';
import '../../../domain/usecases/submit_review_usecase.dart';
import 'my_sessions_event.dart';
import 'my_sessions_state.dart';

class MySessionsBloc extends Bloc<MySessionsEvent, MySessionsState> {
  MySessionsBloc({
    required this._getStudentSessions,
    required this._cancelBooking,
    required this._submitReview,
  }) : super(const MySessionsInitial()) {
    on<MySessionsLoadRequested>(_onLoadRequested, transformer: restartable());
    on<SessionCancelled>(_onSessionCancelled, transformer: sequential());
    on<SessionJoinRequested>(_onJoinRequested, transformer: sequential());
    on<ReviewSubmitted>(_onReviewSubmitted, transformer: droppable());
  }

  final GetStudentSessionsUseCase _getStudentSessions;
  final CancelBookingUseCase _cancelBooking;
  final SubmitReviewUseCase _submitReview;

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

    final result = await _cancelBooking(event.bookingId, reason: event.reason);

    result.fold(
      (failure) => emit(current.clearCancellation()),
      (_) {
        // Remove the cancelled session from upcoming list.
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

  void _onJoinRequested(
    SessionJoinRequested event,
    Emitter<MySessionsState> emit,
  ) {
    // Navigation to the call screen is handled by the UI layer via a
    // BlocListener reacting to this event; no state change needed here.
    // The CallProvider is invoked directly from the screen.
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
      (_) => null, // silently ignore — do not block UI on review failure
      (review) => emit(current.copyWith(lastSubmittedReview: review)),
    );
  }
}
