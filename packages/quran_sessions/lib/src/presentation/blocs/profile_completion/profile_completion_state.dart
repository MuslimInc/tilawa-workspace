import 'package:equatable/equatable.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/market_config.dart';
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

/// Profile + available markets loaded; user is editing fields.
final class ProfileCompletionEditing extends ProfileCompletionState {
  const ProfileCompletionEditing({
    required this.userId,
    required this.availableMarkets,
    required this.minimumStudentAgeYears,
    this.selectedGender,
    this.selectedDateOfBirth,
    this.dobFailure,
    this.selectedMarket,
    this.selectedCity,
    this.submitAttempted = false,
    this.submitValidationAttempt = 0,
    this.genderError,
    this.dateOfBirthRequiredError,
    this.countryError,
    this.cityError,
  });

  final String userId;

  /// All supported markets — used to populate the country picker.
  final List<MarketConfig> availableMarkets;

  /// Configured minimum student age (years), loaded from remote config via the
  /// session policy. Drives both the date picker's `lastDate` and DOB
  /// validation so the UI and domain can never drift.
  final int minimumStudentAgeYears;

  final UserGender? selectedGender;

  /// The validated date of birth. Null means not yet set OR most recent attempt
  /// was invalid (in which case [dobFailure] is non-null).
  final DateTime? selectedDateOfBirth;

  /// Non-null when the most recently attempted DOB was rejected by
  /// [DobValidator]. The UI surfaces this as a field-level error message
  /// via [QuranSessionsFailure.toLocalizedMessage].
  final QuranSessionsFailure? dobFailure;

  /// The country the user has selected.
  final MarketConfig? selectedMarket;

  /// The city within [selectedMarket] the user has selected.
  final CityConfig? selectedCity;

  /// True after the user has tapped submit at least once.
  final bool submitAttempted;

  /// Increments on each failed submit validation pass (drives scroll-to-error).
  final int submitValidationAttempt;

  /// Submit-time gender error copy.
  final String? genderError;

  /// Submit-time required DOB error when no date is selected.
  final String? dateOfBirthRequiredError;

  /// Submit-time country error copy.
  final String? countryError;

  /// Submit-time city error copy.
  final String? cityError;

  /// Cities available for selection in the current [selectedMarket].
  List<CityConfig> get availableCities =>
      selectedMarket?.enabledCities ?? const [];

  bool get canSubmit =>
      selectedGender != null &&
      selectedDateOfBirth != null &&
      dobFailure == null &&
      selectedMarket != null &&
      selectedCity != null &&
      genderError == null &&
      dateOfBirthRequiredError == null &&
      countryError == null &&
      cityError == null;

  String? get visibleGenderError => submitAttempted ? genderError : null;

  String? visibleDateOfBirthError(
    String Function(QuranSessionsFailure) localize,
  ) {
    if (!submitAttempted) {
      return null;
    }
    if (dobFailure != null) {
      return localize(dobFailure!);
    }
    return dateOfBirthRequiredError;
  }

  String? get visibleCountryError => submitAttempted ? countryError : null;

  String? get visibleCityError => submitAttempted ? cityError : null;

  int get invalidFieldCount {
    if (!submitAttempted || canSubmit) {
      return 0;
    }
    return validationIssues.length;
  }

  /// Computes submit-time field errors without mutating user input.
  ProfileCompletionEditing applySubmitValidation() {
    final String? genderErr = selectedGender == null
        ? ProfileCompletionValidationMessages.genderRequired
        : null;
    final String? dobRequiredErr =
        selectedDateOfBirth == null && dobFailure == null
        ? ProfileCompletionValidationMessages.dateOfBirthRequired
        : null;
    final String? countryErr = selectedMarket == null
        ? ProfileCompletionValidationMessages.countryRequired
        : null;
    final String? cityErr = selectedCity == null
        ? ProfileCompletionValidationMessages.cityRequired
        : null;

    return copyWith(
      submitAttempted: true,
      submitValidationAttempt: submitValidationAttempt + 1,
      genderError: genderErr,
      dateOfBirthRequiredError: dobRequiredErr,
      countryError: countryErr,
      cityError: cityErr,
    );
  }

  ProfileCompletionEditing copyWith({
    UserGender? selectedGender,
    DateTime? selectedDateOfBirth,
    QuranSessionsFailure? dobFailure,
    bool clearDob = false,
    bool clearDobFailure = false,
    MarketConfig? selectedMarket,
    CityConfig? selectedCity,
    bool clearCity = false,
    bool? submitAttempted,
    int? submitValidationAttempt,
    String? genderError,
    bool clearGenderError = false,
    String? dateOfBirthRequiredError,
    bool clearDateOfBirthRequiredError = false,
    String? countryError,
    bool clearCountryError = false,
    String? cityError,
    bool clearCityError = false,
  }) => ProfileCompletionEditing(
    userId: userId,
    availableMarkets: availableMarkets,
    minimumStudentAgeYears: minimumStudentAgeYears,
    selectedGender: selectedGender ?? this.selectedGender,
    selectedDateOfBirth: clearDob
        ? null
        : (selectedDateOfBirth ?? this.selectedDateOfBirth),
    dobFailure: clearDobFailure ? null : (dobFailure ?? this.dobFailure),
    selectedMarket: selectedMarket ?? this.selectedMarket,
    selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
    submitAttempted: submitAttempted ?? this.submitAttempted,
    submitValidationAttempt:
        submitValidationAttempt ?? this.submitValidationAttempt,
    genderError: clearGenderError ? null : (genderError ?? this.genderError),
    dateOfBirthRequiredError: clearDateOfBirthRequiredError
        ? null
        : (dateOfBirthRequiredError ?? this.dateOfBirthRequiredError),
    countryError: clearCountryError
        ? null
        : (countryError ?? this.countryError),
    cityError: clearCityError ? null : (cityError ?? this.cityError),
  );

  @override
  List<Object?> get props => [
    userId,
    availableMarkets,
    minimumStudentAgeYears,
    selectedGender,
    selectedDateOfBirth,
    dobFailure,
    selectedMarket,
    selectedCity,
    submitAttempted,
    submitValidationAttempt,
    genderError,
    dateOfBirthRequiredError,
    countryError,
    cityError,
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
  List<TilawaFormFieldIssue> get validationIssues {
    final List<TilawaFormFieldIssue> issues = <TilawaFormFieldIssue>[];
    if (genderError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.gender,
          errorMessage: genderError!,
        ),
      );
    }
    if (dobFailure != null || dateOfBirthRequiredError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.dateOfBirth,
          errorMessage: dateOfBirthRequiredError ?? 'تاريخ الميلاد غير صالح',
        ),
      );
    }
    if (countryError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.country,
          errorMessage: countryError!,
        ),
      );
    }
    if (cityError != null) {
      issues.add(
        TilawaFormFieldIssue(
          fieldId: ProfileCompletionFieldIds.city,
          errorMessage: cityError!,
        ),
      );
    }
    return issues;
  }
}
