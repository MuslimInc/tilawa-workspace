import 'package:equatable/equatable.dart';

import 'manual_payment_price.dart';
import 'session_call_type.dart';
import 'session_price.dart';
import 'session_pricing_type.dart';
import 'teacher_credential.dart';
import 'teacher_verification_status.dart';
import 'user_profile.dart' show UserGender;

/// A verified teacher available for Quran tutoring sessions.
///
/// [price] is the market-resolved [SessionPrice] for the requesting student's
/// country/city. It is null when [pricingType] is [SessionPricingType.free],
/// or when the teacher list was loaded without a market context (e.g. admin
/// view). Never hardcode currency — always read from [price.currencyCode].
class QuranTeacher extends Equatable {
  const QuranTeacher({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.gender,
    required this.verificationStatus,
    required this.supportedCallTypes,
    required this.pricingType,
    required this.specializations,
    required this.languages,
    required this.averageRating,
    required this.totalReviews,
    required this.totalSessionsCompleted,
    this.price,
    this.manualPaymentPrice,
    this.cityName,
    this.countryName,
    this.credentials = const [],
  });

  final String id;
  final String displayName;
  final String bio;
  final String avatarUrl;

  /// Biological gender used for eligibility checks against safety policies.
  final UserGender gender;

  final TeacherVerificationStatus verificationStatus;
  final List<SessionCallType> supportedCallTypes;

  /// Whether this teacher charges for sessions or teaches for free.
  final SessionPricingType pricingType;

  /// Market-resolved price for the student's country/city.
  ///
  /// Null when [pricingType] == [SessionPricingType.free], or when the
  /// teacher list was fetched without a market context.
  final SessionPrice? price;

  /// Presentation-only manual/off-app price for the Egypt pilot. Independent of
  /// the booking engine: when set the UI shows the price + manual-payment
  /// instructions while the booking stays internally free. Never read by
  /// eligibility, booking creation, payment, commission, or payout logic.
  final ManualPaymentPrice? manualPaymentPrice;

  bool get hasManualPaymentPrice => manualPaymentPrice != null;

  /// E.g. ['tajweed', 'hifz', 'tafsir', 'recitation'].
  final List<String> specializations;

  /// BCP-47 language tags, e.g. ['ar', 'en', 'ur'].
  final List<String> languages;

  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;

  /// Optional public location — shown on discovery cards when present.
  final String? cityName;
  final String? countryName;

  /// Teacher-supplied qualifications; [TeacherCredential.isVerified] when admin
  /// confirmed on backend.
  final List<TeacherCredential> credentials;

  bool get isVerified =>
      verificationStatus == TeacherVerificationStatus.verified;

  bool get isFree => pricingType == SessionPricingType.free;

  @override
  List<Object?> get props => [
    id,
    displayName,
    bio,
    avatarUrl,
    gender,
    verificationStatus,
    supportedCallTypes,
    pricingType,
    price,
    manualPaymentPrice,
    specializations,
    languages,
    averageRating,
    totalReviews,
    totalSessionsCompleted,
    cityName,
    countryName,
    credentials,
  ];
}
