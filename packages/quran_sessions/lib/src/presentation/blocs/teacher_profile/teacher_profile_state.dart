import 'package:equatable/equatable.dart';

import '../../../domain/entities/quran_teacher.dart';
import '../../../domain/entities/session_pricing_quote.dart';
import '../../../domain/entities/session_review.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class TeacherProfileState extends Equatable {
  const TeacherProfileState();

  @override
  List<Object?> get props => [];
}

final class TeacherProfileInitial extends TeacherProfileState {
  const TeacherProfileInitial();
}

final class TeacherProfileLoading extends TeacherProfileState {
  const TeacherProfileLoading();
}

final class TeacherProfileSuccess extends TeacherProfileState {
  const TeacherProfileSuccess({
    required this.teacher,
    required this.availability,
    required this.reviews,
    this.isLoadingAvailability = false,
    this.isLoadingMoreReviews = false,
    this.hasMoreReviews = false,
    this.nextReviewCursor,
    this.reportInProgress = false,
    this.reportFailure,
    this.reportSubmitted = false,
    this.pricingQuote,
  });

  final QuranTeacher teacher;
  final List<TeacherAvailability> availability;
  final List<SessionReview> reviews;
  final bool isLoadingAvailability;
  final bool isLoadingMoreReviews;
  final bool hasMoreReviews;
  final String? nextReviewCursor;
  final bool reportInProgress;
  final QuranSessionsFailure? reportFailure;
  final bool reportSubmitted;

  /// Market-resolved pricing for the current viewer — the same source used by
  /// the booking screen. Null while unresolved (badge hides, never "free").
  final SessionPricingQuote? pricingQuote;

  @override
  List<Object?> get props => [
    teacher,
    availability,
    reviews,
    isLoadingAvailability,
    isLoadingMoreReviews,
    hasMoreReviews,
    nextReviewCursor,
    reportInProgress,
    reportFailure,
    reportSubmitted,
    pricingQuote,
  ];

  TeacherProfileSuccess copyWith({
    QuranTeacher? teacher,
    List<TeacherAvailability>? availability,
    List<SessionReview>? reviews,
    bool? isLoadingAvailability,
    bool? isLoadingMoreReviews,
    bool? hasMoreReviews,
    String? nextReviewCursor,
    bool? reportInProgress,
    bool clearReportInProgress = false,
    QuranSessionsFailure? reportFailure,
    bool clearReportFailure = false,
    bool? reportSubmitted,
    bool clearReportSubmitted = false,
    SessionPricingQuote? pricingQuote,
  }) => TeacherProfileSuccess(
    teacher: teacher ?? this.teacher,
    availability: availability ?? this.availability,
    reviews: reviews ?? this.reviews,
    isLoadingAvailability: isLoadingAvailability ?? this.isLoadingAvailability,
    isLoadingMoreReviews: isLoadingMoreReviews ?? this.isLoadingMoreReviews,
    hasMoreReviews: hasMoreReviews ?? this.hasMoreReviews,
    nextReviewCursor: nextReviewCursor ?? this.nextReviewCursor,
    reportInProgress:
        !clearReportInProgress && (reportInProgress ?? this.reportInProgress),
    reportFailure: clearReportFailure
        ? null
        : reportFailure ?? this.reportFailure,
    reportSubmitted:
        !clearReportSubmitted && (reportSubmitted ?? this.reportSubmitted),
    pricingQuote: pricingQuote ?? this.pricingQuote,
  );
}

final class TeacherProfileFailure extends TeacherProfileState {
  const TeacherProfileFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
