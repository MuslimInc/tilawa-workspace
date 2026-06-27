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
    this.manualPaymentPrice,
    this.cityName,
    this.countryName,
    this.credentials = const [],
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

  /// Presentation-only manual/off-app price (Egypt pilot). Read from the teacher
  /// profile doc; never from `pricing/{marketId}`. Does not affect [pricingType]
  /// or the booking engine.
  final ManualPaymentPriceDto? manualPaymentPrice;

  final List<String> specializations;
  final List<String> languages;
  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;
  final String? cityName;
  final String? countryName;
  final List<TeacherCredentialDto> credentials;

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
        manualPaymentPrice: json['manual_payment_price'] != null
            ? ManualPaymentPriceDto.fromJson(
                json['manual_payment_price'] as Map<String, dynamic>,
              )
            : null,
        specializations: List<String>.from(json['specializations'] as List),
        languages: List<String>.from(json['languages'] as List),
        averageRating: (json['average_rating'] as num).toDouble(),
        totalReviews: json['total_reviews'] as int,
        totalSessionsCompleted: json['total_sessions_completed'] as int,
        cityName: json['city_name'] as String?,
        countryName: json['country_name'] as String?,
        credentials: _mapCredentials(json['credentials']),
      );

  static List<TeacherCredentialDto> _mapCredentials(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => TeacherCredentialDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

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
    if (manualPaymentPrice != null)
      'manual_payment_price': manualPaymentPrice!.toJson(),
    'specializations': specializations,
    'languages': languages,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'total_sessions_completed': totalSessionsCompleted,
    if (cityName != null) 'city_name': cityName,
    if (countryName != null) 'country_name': countryName,
    if (credentials.isNotEmpty)
      'credentials': credentials.map((c) => c.toJson()).toList(),
  };
}

class TeacherCredentialDto {
  const TeacherCredentialDto({
    required this.title,
    this.issuer,
    this.isVerified = false,
  });

  final String title;
  final String? issuer;
  final bool isVerified;

  factory TeacherCredentialDto.fromJson(Map<String, dynamic> json) =>
      TeacherCredentialDto(
        title: json['title'] as String? ?? '',
        issuer: json['issuer'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    if (issuer != null) 'issuer': issuer,
    'is_verified': isVerified,
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

// ── ManualPaymentPriceDto ─────────────────────────────────────────────────────

/// Wire representation of the presentation-only manual/off-app price.
///
/// Read from the teacher profile doc field `manualPaymentPrice`
/// (`{ amountMinor, currencyCode }`). Not part of the real pricing engine.
class ManualPaymentPriceDto {
  const ManualPaymentPriceDto({
    required this.amountMinor,
    required this.currencyCode,
  });

  final int amountMinor;
  final String currencyCode;

  factory ManualPaymentPriceDto.fromJson(Map<String, dynamic> json) =>
      ManualPaymentPriceDto(
        amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
        currencyCode: json['currency_code'] as String? ?? 'EGP',
      );

  Map<String, dynamic> toJson() => {
    'amount_minor': amountMinor,
    'currency_code': currencyCode,
  };
}
