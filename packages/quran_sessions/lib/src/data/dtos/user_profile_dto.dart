class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.role,
    required this.accountStatus,
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.countryCode,
    this.countryName,
    this.cityId,
    this.cityName,
    this.currencyCode,
    this.timezone,
    this.restrictionReason,
    this.learningGoals = const [],
  });

  final String userId;
  final String role;
  final String accountStatus;
  final String? displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? countryCode;
  final String? countryName;
  final String? cityId;
  final String? cityName;
  final String? currencyCode;
  final String? timezone;
  final String? restrictionReason;
  final List<String> learningGoals;
}
