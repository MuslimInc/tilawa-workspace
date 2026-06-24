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
    this.pastNextCursor,
    this.isLoadingMorePast = false,
    this.loadMorePastFailure,
    this.cancellationInProgress,
    this.cancellationFailure,
    this.lastSubmittedReview,
    this.joinInProgress,
    this.joinFailure,
    this.joinCompletedSessionId,
  });

  final List<QuranSession> upcoming;
  final List<QuranSession> past;
  final String? pastNextCursor;
  final bool isLoadingMorePast;
  final QuranSessionsFailure? loadMorePastFailure;

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

  /// Set after a successful join so UI can navigate to the call shell.
  final String? joinCompletedSessionId;

  @override
  List<Object?> get props => [
    upcoming,
    past,
    pastNextCursor,
    isLoadingMorePast,
    loadMorePastFailure,
    cancellationInProgress,
    cancellationFailure,
    lastSubmittedReview,
    joinInProgress,
    joinFailure,
    joinCompletedSessionId,
  ];

  MySessionsSuccess copyWith({
    List<QuranSession>? upcoming,
    List<QuranSession>? past,
    String? pastNextCursor,
    bool clearPastNextCursor = false,
    bool? isLoadingMorePast,
    QuranSessionsFailure? loadMorePastFailure,
    bool clearLoadMorePastFailure = false,
    String? cancellationInProgress,
    QuranSessionsFailure? cancellationFailure,
    bool clearCancellationFailure = false,
    SessionReview? lastSubmittedReview,
    String? joinInProgress,
    bool clearJoinInProgress = false,
    QuranSessionsFailure? joinFailure,
    bool clearJoinFailure = false,
    String? joinCompletedSessionId,
    bool clearJoinCompletedSessionId = false,
  }) => MySessionsSuccess(
    upcoming: upcoming ?? this.upcoming,
    past: past ?? this.past,
    pastNextCursor: clearPastNextCursor
        ? null
        : pastNextCursor ?? this.pastNextCursor,
    isLoadingMorePast: isLoadingMorePast ?? this.isLoadingMorePast,
    loadMorePastFailure: clearLoadMorePastFailure
        ? null
        : loadMorePastFailure ?? this.loadMorePastFailure,
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
    joinCompletedSessionId: clearJoinCompletedSessionId
        ? null
        : joinCompletedSessionId ?? this.joinCompletedSessionId,
  );

  /// Returns a copy with cancellation fields cleared.
  MySessionsSuccess clearCancellation() => MySessionsSuccess(
    upcoming: upcoming,
    past: past,
    lastSubmittedReview: lastSubmittedReview,
    joinInProgress: joinInProgress,
    joinFailure: joinFailure,
    joinCompletedSessionId: joinCompletedSessionId,
  );

  /// Returns a copy with join progress/failure cleared.
  MySessionsSuccess clearJoin() => MySessionsSuccess(
    upcoming: upcoming,
    past: past,
    cancellationInProgress: cancellationInProgress,
    cancellationFailure: cancellationFailure,
    lastSubmittedReview: lastSubmittedReview,
    joinCompletedSessionId: joinCompletedSessionId,
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
