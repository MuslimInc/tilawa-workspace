/// Raw JSON shape returned by the backend for a teacher record.
///
/// No codegen dependency yet — add json_serializable/freezed when the
/// actual API contract is finalised.
class QuranTeacherDto {
  const QuranTeacherDto({
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
  final String verificationStatus;
  final List<String> supportedCallTypes;
  final String pricingType;
  final double? pricePerSessionUsd;
  final List<String> specializations;
  final List<String> languages;
  final double averageRating;
  final int totalReviews;
  final int totalSessionsCompleted;

  factory QuranTeacherDto.fromJson(Map<String, dynamic> json) =>
      QuranTeacherDto(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        bio: json['bio'] as String,
        avatarUrl: json['avatar_url'] as String,
        verificationStatus: json['verification_status'] as String,
        supportedCallTypes: List<String>.from(
          json['supported_call_types'] as List,
        ),
        pricingType: json['pricing_type'] as String,
        pricePerSessionUsd: (json['price_per_session_usd'] as num?)?.toDouble(),
        specializations: List<String>.from(json['specializations'] as List),
        languages: List<String>.from(json['languages'] as List),
        averageRating: (json['average_rating'] as num).toDouble(),
        totalReviews: json['total_reviews'] as int,
        totalSessionsCompleted: json['total_sessions_completed'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'verification_status': verificationStatus,
    'supported_call_types': supportedCallTypes,
    'pricing_type': pricingType,
    'price_per_session_usd': pricePerSessionUsd,
    'specializations': specializations,
    'languages': languages,
    'average_rating': averageRating,
    'total_reviews': totalReviews,
    'total_sessions_completed': totalSessionsCompleted,
  };
}
