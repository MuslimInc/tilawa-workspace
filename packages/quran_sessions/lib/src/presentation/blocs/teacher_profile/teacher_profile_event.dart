import 'package:equatable/equatable.dart';

sealed class TeacherProfileEvent extends Equatable {
  const TeacherProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted — load profile, availability, and reviews in parallel.
final class TeacherProfileRequested extends TeacherProfileEvent {
  const TeacherProfileRequested({
    required this.teacherId,
    required this.availabilityFrom,
    required this.availabilityTo,
  });

  final String teacherId;
  final DateTime availabilityFrom;
  final DateTime availabilityTo;

  @override
  List<Object?> get props => [teacherId, availabilityFrom, availabilityTo];
}

/// User navigates to the next/previous week in the availability calendar.
final class AvailabilityWeekChanged extends TeacherProfileEvent {
  const AvailabilityWeekChanged({
    required this.teacherId,
    required this.from,
    required this.to,
  });

  final String teacherId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [teacherId, from, to];
}

/// User loads more reviews (pagination).
final class MoreReviewsRequested extends TeacherProfileEvent {
  const MoreReviewsRequested({required this.teacherId, required this.cursor});

  final String teacherId;
  final String cursor;

  @override
  List<Object?> get props => [teacherId, cursor];
}
