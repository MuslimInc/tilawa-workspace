import '../../domain/entities/user_profile.dart';
import '../dtos/user_profile_dto.dart';

StudentLearningGoal _mapLearningGoal(String raw) => switch (raw) {
  'hifz' => StudentLearningGoal.hifz,
  'tajweed' => StudentLearningGoal.tajweed,
  'arabic' => StudentLearningGoal.arabic,
  _ => StudentLearningGoal.recitation,
};

String _learningGoalCode(StudentLearningGoal goal) => switch (goal) {
  StudentLearningGoal.recitation => 'recitation',
  StudentLearningGoal.hifz => 'hifz',
  StudentLearningGoal.tajweed => 'tajweed',
  StudentLearningGoal.arabic => 'arabic',
};

extension UserProfileDtoMapper on UserProfileDto {
  UserProfile toDomain() => UserProfile(
    userId: userId,
    role: _mapRole(role),
    accountStatus: _mapAccountStatus(accountStatus),
    displayName: displayName,
    gender: gender == null ? null : _mapGender(gender!),
    dateOfBirth: dateOfBirth,
    countryCode: countryCode,
    countryName: countryName,
    cityId: cityId,
    cityName: cityName,
    currencyCode: currencyCode,
    timezone: timezone,
    restrictionReason: restrictionReason == null
        ? null
        : _mapRestrictionReason(restrictionReason!),
    learningGoals: learningGoals.map(_mapLearningGoal).toList(),
  );
}

extension UserProfileDomainMapper on UserProfile {
  UserProfileDto toDto() => UserProfileDto(
    userId: userId,
    role: role.name,
    accountStatus: accountStatus.name,
    displayName: displayName,
    gender: gender?.name,
    dateOfBirth: dateOfBirth,
    countryCode: countryCode,
    countryName: countryName,
    cityId: cityId,
    cityName: cityName,
    currencyCode: currencyCode,
    timezone: timezone,
    restrictionReason: restrictionReason?.name,
    learningGoals: learningGoals.map(_learningGoalCode).toList(),
  );
}

UserRole _mapRole(String raw) => switch (raw) {
  'admin' => UserRole.admin,
  'moderator' => UserRole.moderator,
  _ => UserRole.student,
};

AccountStatus _mapAccountStatus(String raw) => switch (raw) {
  'underReview' => AccountStatus.underReview,
  'suspended' => AccountStatus.suspended,
  'blocked' => AccountStatus.blocked,
  _ => AccountStatus.active,
};

UserGender _mapGender(String raw) => switch (raw) {
  'female' => UserGender.female,
  _ => UserGender.male,
};

AccountRestrictionReason _mapRestrictionReason(String raw) => switch (raw) {
  'falseIdentity' => AccountRestrictionReason.falseIdentity,
  'policyViolation' => AccountRestrictionReason.policyViolation,
  'safetyConcern' => AccountRestrictionReason.safetyConcern,
  'abuseReport' => AccountRestrictionReason.abuseReport,
  'repeatedNoShow' => AccountRestrictionReason.repeatedNoShow,
  _ => AccountRestrictionReason.adminDecision,
};
