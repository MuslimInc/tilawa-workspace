import 'package:equatable/equatable.dart';

sealed class MySessionsEvent extends Equatable {
  const MySessionsEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted or pull-to-refresh triggered.
final class MySessionsLoadRequested extends MySessionsEvent {
  const MySessionsLoadRequested({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}

/// User cancels an upcoming session from the list.
final class SessionCancelled extends MySessionsEvent {
  const SessionCancelled({
    required this.bookingId,
    required this.reason,
  });

  final String bookingId;
  final String reason;

  @override
  List<Object?> get props => [bookingId, reason];
}

/// User taps the "Join" button on an upcoming session.
final class SessionJoinRequested extends MySessionsEvent {
  const SessionJoinRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// User submits a star rating + comment for a completed session.
final class ReviewSubmitted extends MySessionsEvent {
  const ReviewSubmitted({
    required this.sessionId,
    required this.rating,
    this.comment,
  });

  final String sessionId;
  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [sessionId, rating, comment];
}
