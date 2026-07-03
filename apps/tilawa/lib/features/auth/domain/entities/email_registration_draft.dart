import 'package:equatable/equatable.dart';

/// In-memory registration payload collected before Firebase Auth user creation.
class EmailRegistrationDraft extends Equatable {
  const EmailRegistrationDraft({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.gender,
    this.dateOfBirth,
    this.countryCode,
    this.countryName,
    this.cityId,
    this.cityName,
    this.currencyCode,
    this.timezone,
    this.preferredLanguageCode,
    this.learningGoals = const <String>[],
    this.guardianConsentAcknowledged = false,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? countryCode;
  final String? countryName;
  final String? cityId;
  final String? cityName;
  final String? currencyCode;
  final String? timezone;
  final String? preferredLanguageCode;
  final List<String> learningGoals;
  final bool guardianConsentAcknowledged;

  bool get hasAccountFields =>
      email.trim().isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty;

  bool get hasPersonalFields =>
      displayName.trim().isNotEmpty &&
      gender != null &&
      dateOfBirth != null &&
      countryCode != null &&
      cityId != null &&
      preferredLanguageCode != null;

  bool get hasLearningFields => learningGoals.isNotEmpty;

  EmailRegistrationDraft copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? countryCode,
    String? countryName,
    String? cityId,
    String? cityName,
    String? currencyCode,
    String? timezone,
    bool clearLocation = false,
    String? preferredLanguageCode,
    List<String>? learningGoals,
    bool? guardianConsentAcknowledged,
  }) {
    return EmailRegistrationDraft(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      countryCode: clearLocation ? null : (countryCode ?? this.countryCode),
      countryName: clearLocation ? null : (countryName ?? this.countryName),
      cityId: clearLocation ? null : (cityId ?? this.cityId),
      cityName: clearLocation ? null : (cityName ?? this.cityName),
      currencyCode: clearLocation ? null : (currencyCode ?? this.currencyCode),
      timezone: clearLocation ? null : (timezone ?? this.timezone),
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      learningGoals: learningGoals ?? this.learningGoals,
      guardianConsentAcknowledged:
          guardianConsentAcknowledged ?? this.guardianConsentAcknowledged,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    email,
    password,
    confirmPassword,
    displayName,
    gender,
    dateOfBirth,
    countryCode,
    countryName,
    cityId,
    cityName,
    currencyCode,
    timezone,
    preferredLanguageCode,
    learningGoals,
    guardianConsentAcknowledged,
  ];
}
