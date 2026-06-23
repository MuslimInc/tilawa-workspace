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
    this.cancellationFailure,
    this.lastSubmittedReview,
    this.joinInProgress,
    this.joinFailure,
  });

  final List<QuranSession> upcoming;
  final List<QuranSession> past;

  /// ID of the booking currently being cancelled; drives a per-row spinner.
  final String? cancellationInProgress;

  /// Set when cancellation fails so UI can show feedback.
  final QuranSessionsFailure? cancellationFailure;

  /// Set after a review is submitted so the UI can show a confirmation snack.
  final SessionReview? lastSubmittedReview;

  /// Session id currently launching the meeting link.
  final String? joinInProgress;

  /// Set when join fails so UI can show feedback.
  final QuranSessionsFailure? joinFailure;

  @override
  List<Object?> get props => [
    upcoming,
    past,
    cancellationInProgress,
    cancellationFailure,
    lastSubmittedReview,
    joinInProgress,
    joinFailure,
  ];

  MySessionsSuccess copyWith({
    List<QuranSession>? upcoming,
    List<QuranSession>? past,
    String? cancellationInProgress,
    QuranSessionsFailure? cancellationFailure,
    bool clearCancellationFailure = false,
    SessionReview? lastSubmittedReview,
    String? joinInProgress,
    bool clearJoinInProgress = false,
    QuranSessionsFailure? joinFailure,
    bool clearJoinFailure = false,
  }) => MySessionsSuccess(
    upcoming: upcoming ?? this.upcoming,
    past: past ?? this.past,
    cancellationInProgress:
        cancellationInProgress ?? this.cancellationInProgress,
    cancellationFailure: clearCancellationFailure
        ? null
        : cancellationFailure ?? this.cancellationFailure,
    lastSubmittedReview: lastSubmittedReview ?? this.lastSubmittedReview,
    joinInProgress: clearJoinInProgress
        ? null
        : joinInProgress ?? this.joinInProgress,
    joinFailure: clearJoinFailure ? null : joinFailure ?? this.joinFailure,
  );

  /// Returns a copy with cancellation fields cleared.
  MySessionsSuccess clearCancellation() => MySessionsSuccess(
    upcoming: upcoming,
    past: past,
    lastSubmittedReview: lastSubmittedReview,
    joinInProgress: joinInProgress,
    joinFailure: joinFailure,
  );

  /// Returns a copy with join progress/failure cleared.
  MySessionsSuccess clearJoin() => MySessionsSuccess(
    upcoming: upcoming,
    past: past,
    cancellationInProgress: cancellationInProgress,
    cancellationFailure: cancellationFailure,
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
