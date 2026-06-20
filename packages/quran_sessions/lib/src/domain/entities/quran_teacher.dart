import 'package:equatable/equatable.dart';

import 'session_call_type.dart';
import 'session_pricing_type.dart';
import 'teacher_verification_status.dart';

/// A verified teacher available for Quran tutoring sessions.
class QuranTeacher extends Equatable {
  const QuranTeacher({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.verificationStatus,
    required this.supportedCallTypes,
    required this.pricingType,
    required this.pricePerSessionUsd,
    required this.specializations,
    required this.languages,
    required this.averageRating,
    required this.totalReviews,
    required this.totalSessionsCompleted,
  });

  final String id;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final TeacherVerificationStatus verificationStatus;
  final List<SessionCallType> supportedCallTypes;
  final SessionPricingType pricingType;

  /// Null when [pricingType] is [SessionPricingType.free] or [SessionPricingType.subscription].
  final double? pricePerSessionUsd;

  /// E.g. ['tajweed', 'hifz', 'tafsir', 'recitation'].
  final List<String> specializations;

  /// BCP-47 language tags, e.g. ['ar', 'en', 'ur'].
  final List<String> languages;

  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;

  bool get isVerified =>
      verificationStatus == TeacherVerificationStatus.verified;

  @override
  List<Object?> get props => [
    id,
    displayName,
    bio,
    avatarUrl,
    verificationStatus,
    supportedCallTypes,
    pricingType,
    pricePerSessionUsd,
    specializations,
    languages,
    averageRating,
    totalReviews,
    totalSessionsCompleted,
  ];
}
