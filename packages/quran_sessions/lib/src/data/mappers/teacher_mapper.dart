import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_price.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../domain/entities/teacher_verification_status.dart';
import '../../domain/entities/user_profile.dart' show UserGender;
import '../dtos/quran_teacher_dto.dart';

extension QuranTeacherDtoMapper on QuranTeacherDto {
  QuranTeacher toDomain() => QuranTeacher(
    id: id,
    displayName: displayName,
    bio: bio,
    avatarUrl: avatarUrl,
    gender: _mapGender(gender),
    verificationStatus: _mapVerificationStatus(verificationStatus),
    supportedCallTypes: supportedCallTypes.map(_mapCallType).toList(),
    pricingType: _mapPricingType(pricingType),
    price: marketPrice?.toDomain(),
    specializations: specializations,
    languages: languages,
    averageRating: averageRating,
    totalReviews: totalReviews,
    totalSessionsCompleted: totalSessionsCompleted,
    cityName: cityName,
    countryName: countryName,
  );
}

extension SessionPriceDtoMapper on SessionPriceDto {
  SessionPrice toDomain() => SessionPrice(
    amount: amount,
    currencyCode: currencyCode,
    countryCode: countryCode,
    cityId: cityId,
  );
}

UserGender _mapGender(String raw) => switch (raw) {
  'female' => UserGender.female,
  _ => UserGender.male,
};

TeacherVerificationStatus _mapVerificationStatus(String raw) => switch (raw) {
  'pending' => TeacherVerificationStatus.pending,
  'under_review' => TeacherVerificationStatus.underReview,
  'verified' => TeacherVerificationStatus.verified,
  'rejected' => TeacherVerificationStatus.rejected,
  'suspended' => TeacherVerificationStatus.suspended,
  _ => TeacherVerificationStatus.pending,
};

SessionCallType _mapCallType(String raw) => switch (raw) {
  'external_meeting' => SessionCallType.externalMeeting,
  'voice_call' => SessionCallType.voiceCall,
  'video_call' => SessionCallType.videoCall,
  _ => SessionCallType.externalMeeting,
};

SessionPricingType _mapPricingType(String raw) => switch (raw) {
  'free' => SessionPricingType.free,
  'fixed_per_session' => SessionPricingType.fixedPerSession,
  'subscription' => SessionPricingType.subscription,
  _ => SessionPricingType.free,
};
