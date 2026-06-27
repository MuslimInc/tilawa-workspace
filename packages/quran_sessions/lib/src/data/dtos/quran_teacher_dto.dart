/// Raw JSON shape returned by the backend for a teacher record.
///
/// [marketPrice] is the market-resolved price for the requesting student's
/// country/city. The backend injects this at query time from
/// `teachers/{id}/pricing/{marketId}`. When null the teacher has no price
/// configured for that market (or the query was made without market context).
///
/// No codegen dependency yet — add json_serializable/freezed when the
/// actual API contract is finalised.
class QuranTeacherDto {
  const QuranTeacherDto({
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
    this.marketPrice,
    this.cityName,
    this.countryName,
  });

  final String id;
  final String displayName;
  final String bio;
  final String avatarUrl;

  /// 'male' | 'female'
  final String gender;

  final String verificationStatus;
  final List<String> supportedCallTypes;
  final String pricingType;

  /// Market-resolved price, injected by the backend per student market.
  /// Null for free teachers or when queried without a market context.
  final SessionPriceDto? marketPrice;

  final List<String> specializations;
  final List<String> languages;
  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;
  final String? cityName;
  final String? countryName;

  factory QuranTeacherDto.fromJson(Map<String, dynamic> json) =>
      QuranTeacherDto(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        bio: json['bio'] as String,
        avatarUrl: json['avatar_url'] as String,
        gender: json['gender'] as String? ?? 'male',
        verificationStatus: json['verification_status'] as String,
        supportedCallTypes: List<String>.from(
          json['supported_call_types'] as List,
        ),
        pricingType: json['pricing_type'] as String,
        marketPrice: json['market_price'] != null
            ? SessionPriceDto.fromJson(
                json['market_price'] as Map<String, dynamic>,
              )
            : null,
        specializations: List<String>.from(json['specializations'] as List),
        languages: List<String>.from(json['languages'] as List),
        averageRating: (json['average_rating'] as num).toDouble(),
        totalReviews: json['total_reviews'] as int,
        totalSessionsCompleted: json['total_sessions_completed'] as int,
        cityName: json['city_name'] as String?,
        countryName: json['country_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'gender': gender,
    'verification_status': verificationStatus,
    'supported_call_types': supportedCallTypes,
    'pricing_type': pricingType,
    'market_price': marketPrice?.toJson(),
    'specializations': specializations,
    'languages': languages,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'total_sessions_completed': totalSessionsCompleted,
    if (cityName != null) 'city_name': cityName,
    if (countryName != null) 'country_name': countryName,
  };
}

// ── SessionPriceDto ───────────────────────────────────────────────────────────

/// Wire representation of a market-resolved session price.
///
/// Mirrors Firestore path: `teachers/{id}/pricing/{marketId}`
class SessionPriceDto {
  const SessionPriceDto({
    required this.amount,
    required this.currencyCode,
    required this.countryCode,
    this.cityId,
  });

  final double amount;
  final String currencyCode;
  final String countryCode;
  final String? cityId;

  factory SessionPriceDto.fromJson(Map<String, dynamic> json) =>
      SessionPriceDto(
        amount: (json['amount'] as num).toDouble(),
        currencyCode: json['currency_code'] as String,
        countryCode: json['country_code'] as String,
        cityId: json['city_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency_code': currencyCode,
    'country_code': countryCode,
    if (cityId != null) 'city_id': cityId,
  };
}
