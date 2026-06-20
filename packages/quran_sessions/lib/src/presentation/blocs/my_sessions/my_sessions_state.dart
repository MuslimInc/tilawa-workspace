import 'package:equatable/equatable.dart';

import '../../../domain/entities/quran_session.dart';
import '../../../domain/entities/session_review.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class MySessionsState extends Equatable {
  const MySessionsState();

  @override
  List<Object?> get props => [];
}

final class MySessionsInitial extends MySessionsState {
  const MySessionsInitial();
}

final class MySessionsLoading extends MySessionsState {
  const MySessionsLoading();
}

final class MySessionsSuccess extends MySessionsState {
  const MySessionsSuccess({
    required this.upcoming,
    required this.past,
    this.cancellationInProgress,
    this.lastSubmittedReview,
  });

  final List<QuranSession> upcoming;
  final List<QuranSession> past;

  /// ID of the booking currently being cancelled; drives a per-row spinner.
  final String? cancellationInProgress;

  /// Set after a review is submitted so the UI can show a confirmation snack.
  final SessionReview? lastSubmittedReview;

  @override
  List<Object?> get props => [
    upcoming,
    past,
    cancellationInProgress,
    lastSubmittedReview,
  ];

  MySessionsSuccess copyWith({
    List<QuranSession>? upcoming,
    List<QuranSession>? past,
    String? cancellationInProgress,
    SessionReview? lastSubmittedReview,
  }) => MySessionsSuccess(
    upcoming: upcoming ?? this.upcoming,
    past: past ?? this.past,
    cancellationInProgress:
        cancellationInProgress ?? this.cancellationInProgress,
    lastSubmittedReview: lastSubmittedReview ?? this.lastSubmittedReview,
  );

  /// Returns a copy with [cancellationInProgress] cleared.
  MySessionsSuccess clearCancellation() => MySessionsSuccess(
    upcoming: upcoming,
    past: past,
    lastSubmittedReview: lastSubmittedReview,
  );
}

final class MySessionsEmpty extends MySessionsState {
  const MySessionsEmpty();
}

final class MySessionsFailure extends MySessionsState {
  const MySessionsFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
