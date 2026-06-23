import 'package:equatable/equatable.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/market_city.dart';
import '../../../domain/entities/market_country.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../forms/profile_completion_field_ids.dart';

sealed class ProfileCompletionState extends Equatable {
  const ProfileCompletionState();

  @override
  List<Object?> get props => [];
}

final class ProfileCompletionInitial extends ProfileCompletionState {
  const ProfileCompletionInitial();
}

final class ProfileCompletionLoading extends ProfileCompletionState {
  const ProfileCompletionLoading();
}

/// Profile + available countries loaded; user is editing fields.
final class ProfileCompletionEditing extends ProfileCompletionState {
  const ProfileCompletionEditing({
    required this.userId,
    required this.availableCountries,
    required this.minimumStudentAgeYears,
    this.availableCities = const [],
    this.selectedCountry,
    this.selectedCity,
    this.isLoadingCities = false,
    this.countryPickerLocked = false,
    this.cityPickerLocked = false,
    this.selectedGender,
    this.selectedDateOfBirth,
    this.dobFailure,
    this.submitAttempted = false,
    this.submitValidationAttempt = 0,
  });

  final String userId;
  final List<MarketCountry> availableCountries;
  final List<MarketCity> availableCities;
  final int minimumStudentAgeYears;

  final MarketCountry? selectedCountry;
  final MarketCity? selectedCity;

  /// True while cities for the selected country are being fetched.
  final bool isLoadingCities;

  /// When only one enabled country exists, the picker is read-only.
  final bool countryPickerLocked;

  /// When only one enabled city exists for the country, the picker is read-only.
  final bool cityPickerLocked;

  final UserGender? selectedGender;
  final DateTime? selectedDateOfBirth;
  final QuranSessionsFailure? dobFailure;
  final bool submitAttempted;
  final int submitValidationAttempt;

  bool get hasGenderError => submitAttempted && selectedGender == null;

  bool get hasDateOfBirthRequiredError =>
      submitAttempted && selectedDateOfBirth == null && dobFailure == null;

  bool get hasCountryError => submitAttempted && selectedCountry == null;

  bool get hasCityError => submitAttempted && selectedCity == null;

  bool get canSubmit =>
      selectedGender != null &&
      selectedDateOfBirth != null &&
      dobFailure == null &&
      selectedCountry != null &&
      selectedCity != null &&
      !isLoadingCities &&
      !hasGenderError &&
      !hasDateOfBirthRequiredError &&
      !hasCountryError &&
      !hasCityError;

  String? genderErrorFor(QuranSessionsLocalizations l10n) =>
      hasGenderError ? l10n.profileGenderRequired : null;

  String? countryErrorFor(QuranSessionsLocalizations l10n) =>
      hasCountryError ? l10n.profileCountryRequired : null;

  String? cityErrorFor(QuranSessionsLocalizations l10n) =>
      hasCityError ? l10n.profileCityRequired : null;

  String? visibleDateOfBirthError(
    QuranSessionsLocalizations l10n,
    String Function(QuranSessionsFailure) localizeFailure,
  ) {
    if (!submitAttempted) return null;
    if (dobFailure != null) return localizeFailure(dobFailure!);
    if (hasDateOfBirthRequiredError) return l10n.dateOfBirthRequired;
    return null;
  }

  int get invalidFieldCount {
    if (!submitAttempted || canSubmit) return 0;
    var count = 0;
    if (hasGenderError) count++;
    if (hasDateOfBirthRequiredError || dobFailure != null) count++;
    if (hasCountryError) count++;
    if (hasCityError) count++;
    return count;
  }

  ProfileCompletionEditing applySubmitValidation() => copyWith(
    submitAttempted: true,
    submitValidationAttempt: submitValidationAttempt + 1,
  );

  ProfileCompletionEditing copyWith({
    List<MarketCity>? availableCities,
    MarketCountry? selectedCountry,
    MarketCity? selectedCity,
    bool clearCity = false,
    bool? isLoadingCities,
    bool? countryPickerLocked,
    bool? cityPickerLocked,
    UserGender? selectedGender,
    DateTime? selectedDateOfBirth,
    QuranSessionsFailure? dobFailure,
    bool clearDob = false,
    bool clearDobFailure = false,
    bool? submitAttempted,
    int? submitValidationAttempt,
  }) => ProfileCompletionEditing(
    userId: userId,
    availableCountries: availableCountries,
    minimumStudentAgeYears: minimumStudentAgeYears,
    availableCities: availableCities ?? this.availableCities,
    selectedCountry: selectedCountry ?? this.selectedCountry,
    selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
    isLoadingCities: isLoadingCities ?? this.isLoadingCities,
    countryPickerLocked: countryPickerLocked ?? this.countryPickerLocked,
    cityPickerLocked: cityPickerLocked ?? this.cityPickerLocked,
    selectedGender: selectedGender ?? this.selectedGender,
    selectedDateOfBirth: clearDob
        ? null
        : (selectedDateOfBirth ?? this.selectedDateOfBirth),
    dobFailure: clearDobFailure ? null : (dobFailure ?? this.dobFailure),
    submitAttempted: submitAttempted ?? this.submitAttempted,
    submitValidationAttempt:
        submitValidationAttempt ?? this.submitValidationAttempt,
  );

  @override
  List<Object?> get props => [
    userId,
    availableCountries,
    availableCities,
    minimumStudentAgeYears,
    selectedCountry,
    selectedCity,
    isLoadingCities,
    countryPickerLocked,
    cityPickerLocked,
    selectedGender,
    selectedDateOfBirth,
    dobFailure,
    submitAttempted,
    submitValidationAttempt,
  ];
}

final class ProfileCompletionSaving extends ProfileCompletionState {
  const ProfileCompletionSaving();
}

final class ProfileCompletionSaved extends ProfileCompletionState {
  const ProfileCompletionSaved(this.profile);

  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class ProfileCompletionFailure extends ProfileCompletionState {
  const ProfileCompletionFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}

extension ProfileCompletionEditingValidation on ProfileCompletionEditing {
  List<TilawaFormFieldIssue> validationIssues(
    QuranSessionsLocalizations l10n,
    String Function(QuranSessionsFailure) localizeFailure,
  ) {
    final List<TilawaFormFieldIssue> issues = <TilawaFormFieldIssue>[];
    final genderError = genderErrorFor(l10n);
    if (genderError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.gender,
          errorMessage: genderError,
        ),
      );
    }
    final dateOfBirthError = visibleDateOfBirthError(l10n, localizeFailure);
    if (dateOfBirthError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.dateOfBirth,
          errorMessage: dateOfBirthError,
        ),
      );
    }
    final countryError = countryErrorFor(l10n);
    if (countryError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.country,
          errorMessage: countryError,
        ),
      );
    }
    final cityError = cityErrorFor(l10n);
    if (cityError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.city,
          errorMessage: cityError,
        ),
      );
    }
    return issues;
  }
}
