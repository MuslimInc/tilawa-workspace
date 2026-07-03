import 'package:equatable/equatable.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/email_registration_step.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/policies/email_registration_form_policy.dart';

enum EmailRegistrationStatus {
  editing,
  submitting,
  profilePersistenceFailed,
}

class EmailRegistrationState extends Equatable {
  const EmailRegistrationState({
    this.status = EmailRegistrationStatus.editing,
    this.currentStep = EmailRegistrationStep.account,
    this.draft = const EmailRegistrationDraft(),
    this.fieldErrors = const <String, String?>{},
    this.availableCountries = const <MarketCountry>[],
    this.availableCities = const <MarketCity>[],
    this.selectedCountry,
    this.selectedCity,
    this.isLoadingMarketData = true,
    this.isLoadingCities = false,
    this.countryPickerLocked = false,
    this.cityPickerLocked = false,
    this.minimumStudentAgeYears = 5,
    this.childAgeThreshold = 13,
    this.marketDataErrorKey,
    this.authenticatedUser,
  });

  final EmailRegistrationStatus status;
  final EmailRegistrationStep currentStep;
  final EmailRegistrationDraft draft;
  final Map<String, String?> fieldErrors;
  final List<MarketCountry> availableCountries;
  final List<MarketCity> availableCities;
  final MarketCountry? selectedCountry;
  final MarketCity? selectedCity;
  final bool isLoadingMarketData;
  final bool isLoadingCities;
  final bool countryPickerLocked;
  final bool cityPickerLocked;
  final int minimumStudentAgeYears;
  final int childAgeThreshold;
  final String? marketDataErrorKey;
  final UserEntity? authenticatedUser;

  bool get requiresGuardianStep =>
      EmailRegistrationFormPolicy.requiresGuardianStep(
        dateOfBirth: draft.dateOfBirth,
        childAgeThreshold: childAgeThreshold,
      );

  int get visibleStepCount => EmailRegistrationStepX.visibleStepCount(
    includesGuardian: requiresGuardianStep,
  );

  int get currentStepDisplayIndex => currentStep.displayIndex(
    includesGuardian: requiresGuardianStep,
  );

  bool get isSubmitting => status == EmailRegistrationStatus.submitting;

  bool get canGoBack => currentStep != EmailRegistrationStep.account;

  String? fieldError(String key) => fieldErrors[key];

  EmailRegistrationState copyWith({
    EmailRegistrationStatus? status,
    EmailRegistrationStep? currentStep,
    EmailRegistrationDraft? draft,
    Map<String, String?>? fieldErrors,
    bool clearFieldErrors = false,
    List<MarketCountry>? availableCountries,
    List<MarketCity>? availableCities,
    MarketCountry? selectedCountry,
    MarketCity? selectedCity,
    bool clearCity = false,
    bool? isLoadingMarketData,
    bool? isLoadingCities,
    bool? countryPickerLocked,
    bool? cityPickerLocked,
    int? minimumStudentAgeYears,
    int? childAgeThreshold,
    String? marketDataErrorKey,
    bool clearMarketDataError = false,
    UserEntity? authenticatedUser,
    bool clearAuthenticatedUser = false,
  }) {
    return EmailRegistrationState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      fieldErrors: clearFieldErrors
          ? const <String, String?>{}
          : (fieldErrors ?? this.fieldErrors),
      availableCountries: availableCountries ?? this.availableCountries,
      availableCities: availableCities ?? this.availableCities,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
      isLoadingMarketData: isLoadingMarketData ?? this.isLoadingMarketData,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      countryPickerLocked: countryPickerLocked ?? this.countryPickerLocked,
      cityPickerLocked: cityPickerLocked ?? this.cityPickerLocked,
      minimumStudentAgeYears:
          minimumStudentAgeYears ?? this.minimumStudentAgeYears,
      childAgeThreshold: childAgeThreshold ?? this.childAgeThreshold,
      marketDataErrorKey: clearMarketDataError
          ? null
          : (marketDataErrorKey ?? this.marketDataErrorKey),
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    currentStep,
    draft,
    fieldErrors,
    availableCountries,
    availableCities,
    selectedCountry,
    selectedCity,
    isLoadingMarketData,
    isLoadingCities,
    countryPickerLocked,
    cityPickerLocked,
    minimumStudentAgeYears,
    childAgeThreshold,
    marketDataErrorKey,
    authenticatedUser,
  ];
}
