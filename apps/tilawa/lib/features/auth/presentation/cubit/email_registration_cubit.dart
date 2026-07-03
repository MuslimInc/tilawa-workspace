import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/email_registration_step.dart';
import '../../domain/entities/register_with_email_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/policies/email_registration_form_policy.dart';
import '../../domain/usecases/register_with_email_use_case.dart';
import 'email_registration_state.dart';

@injectable
class EmailRegistrationCubit extends Cubit<EmailRegistrationState> {
  EmailRegistrationCubit(
    this._getMarketConfig,
    this._getSessionPolicy,
    this._registerWithEmail,
  ) : super(const EmailRegistrationState());

  final GetMarketConfigUseCase _getMarketConfig;
  final GetSessionPolicyUseCase _getSessionPolicy;
  final RegisterWithEmailUseCase _registerWithEmail;

  Future<void> initialize() async {
    emit(state.copyWith(isLoadingMarketData: true, clearMarketDataError: true));

    final countriesResult = await _getMarketConfig.supportedCountries();
    final policyResult = await _getSessionPolicy();

    if (countriesResult.isLeft() || policyResult.isLeft()) {
      emit(
        state.copyWith(
          isLoadingMarketData: false,
          marketDataErrorKey: 'authErrorGenericMessage',
        ),
      );
      return;
    }

    final countries = countriesResult.fold(
      (_) => throw StateError(''),
      (List<MarketCountry> value) => value,
    );
    final policy = policyResult.fold(
      (_) => throw StateError(''),
      (QuranSessionSafetyPolicy value) => value,
    );

    final bool countryPickerLocked = countries.length == 1;
    MarketCountry? selectedCountry = countryPickerLocked
        ? countries.first
        : null;

    var nextState = state.copyWith(
      isLoadingMarketData: false,
      availableCountries: countries,
      countryPickerLocked: countryPickerLocked,
      selectedCountry: selectedCountry,
      minimumStudentAgeYears: policy.minimumStudentAgeYears,
      childAgeThreshold: policy.childAgeThreshold,
      draft: state.draft.copyWith(
        preferredLanguageCode:
            state.draft.preferredLanguageCode ??
            LanguageConfig.defaultLanguageCode,
      ),
    );

    if (selectedCountry != null) {
      nextState = nextState.copyWith(isLoadingCities: true);
      emit(nextState);
      nextState = await _loadCitiesForCountry(nextState, selectedCountry);
    }

    emit(nextState);
  }

  void emailChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(email: value),
        fieldErrors: _clearFieldError('email'),
      ),
    );
  }

  void passwordChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(password: value),
        fieldErrors: _clearFieldErrors(<String>['password', 'confirmPassword']),
      ),
    );
  }

  void confirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(confirmPassword: value),
        fieldErrors: _clearFieldError('confirmPassword'),
      ),
    );
  }

  void displayNameChanged(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(displayName: value),
        fieldErrors: _clearFieldError('displayName'),
      ),
    );
  }

  void genderSelected(UserGender gender) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(gender: gender.name),
        fieldErrors: _clearFieldError('gender'),
      ),
    );
  }

  void dateOfBirthSet(DateTime value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(dateOfBirth: value),
        fieldErrors: _clearFieldError('dateOfBirth'),
      ),
    );
  }

  Future<void> countrySelected(MarketCountry country) async {
    emit(
      state.copyWith(
        selectedCountry: country,
        clearCity: true,
        availableCities: const <MarketCity>[],
        isLoadingCities: true,
        cityPickerLocked: false,
        draft: state.draft.copyWith(clearLocation: true),
        fieldErrors: _clearFieldErrors(<String>['country', 'city']),
      ),
    );

    final updated = await _loadCitiesForCountry(state, country);
    emit(updated);
  }

  void citySelected(MarketCity city) {
    final MarketCountry? country = state.selectedCountry;
    emit(
      state.copyWith(
        selectedCity: city,
        draft: state.draft.copyWith(
          countryCode: country?.countryCode ?? city.countryCode,
          countryName: country?.countryName,
          cityId: city.cityId,
          cityName: city.cityName,
          currencyCode: city.currencyCode,
          timezone: city.timezone,
        ),
        fieldErrors: _clearFieldError('city'),
      ),
    );
  }

  void preferredLanguageSelected(String languageCode) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(preferredLanguageCode: languageCode),
        fieldErrors: _clearFieldError('preferredLanguage'),
      ),
    );
  }

  void learningGoalToggled(StudentLearningGoal goal) {
    final String code = goal.name;
    final List<String> current = List<String>.from(state.draft.learningGoals);
    if (current.contains(code)) {
      current.remove(code);
    } else {
      current.add(code);
    }
    emit(
      state.copyWith(
        draft: state.draft.copyWith(learningGoals: current),
        fieldErrors: _clearFieldError('learningGoals'),
      ),
    );
  }

  void guardianConsentToggled(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(guardianConsentAcknowledged: value),
        fieldErrors: _clearFieldError('guardianConsent'),
      ),
    );
  }

  bool validateCurrentStep() {
    final Map<String, String?> errors =
        EmailRegistrationFormPolicy.validateStep(
          step: state.currentStep,
          draft: state.draft,
          requiresGuardianStep: state.requiresGuardianStep,
        );
    final bool valid = errors.values.every((String? value) => value == null);
    emit(state.copyWith(fieldErrors: errors));
    return valid;
  }

  void goBack() {
    if (!state.canGoBack) {
      return;
    }
    final EmailRegistrationStep? previous = state.currentStep.previous(
      includesGuardian: state.requiresGuardianStep,
    );
    if (previous == null) {
      return;
    }
    emit(
      state.copyWith(
        currentStep: previous,
        clearFieldErrors: true,
      ),
    );
  }

  bool goNext() {
    if (!validateCurrentStep()) {
      return false;
    }
    final EmailRegistrationStep? next = state.currentStep.next(
      includesGuardian: state.requiresGuardianStep,
    );
    if (next == null) {
      return false;
    }
    emit(
      state.copyWith(
        currentStep: next,
        clearFieldErrors: true,
      ),
    );
    return true;
  }

  EmailRegistrationDraft buildSubmissionDraft() => state.draft;

  void onRegistrationAuthFailed({String? emailErrorKey}) {
    final Map<String, String?> fieldErrors = emailErrorKey == null
        ? state.fieldErrors
        : <String, String?>{
            ...state.fieldErrors,
            'email': emailErrorKey,
          };
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.editing,
        currentStep: EmailRegistrationStep.account,
        fieldErrors: fieldErrors,
      ),
    );
  }

  void markProfilePersistenceFailed(UserEntity user) {
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.profilePersistenceFailed,
        authenticatedUser: user,
      ),
    );
  }

  void clearProfilePersistenceFailure() {
    emit(
      state.copyWith(
        status: EmailRegistrationStatus.editing,
        clearAuthenticatedUser: true,
      ),
    );
  }

  Future<RegisterWithEmailResult?> retryProfilePersistence() async {
    final UserEntity? user = state.authenticatedUser;
    if (user == null) {
      return null;
    }
    emit(state.copyWith(status: EmailRegistrationStatus.submitting));
    final RegisterWithEmailResult result = await _registerWithEmail
        .retryProfilePersistence(
          user: user,
          draft: state.draft,
        );

    switch (result) {
      case RegisterWithEmailCompleted():
        emit(
          state.copyWith(
            status: EmailRegistrationStatus.editing,
            clearAuthenticatedUser: true,
          ),
        );
      case RegisterWithEmailAuthFailed():
        emit(state.copyWith(status: EmailRegistrationStatus.editing));
      case RegisterWithEmailProfilePersistenceFailed(:final user):
        emit(
          state.copyWith(
            status: EmailRegistrationStatus.profilePersistenceFailed,
            authenticatedUser: user,
          ),
        );
    }

    return result;
  }

  Future<EmailRegistrationState> _loadCitiesForCountry(
    EmailRegistrationState current,
    MarketCountry country,
  ) async {
    final citiesResult = await _getMarketConfig.citiesByCountry(
      country.countryCode,
    );
    if (citiesResult.isLeft()) {
      return current.copyWith(
        isLoadingCities: false,
        marketDataErrorKey: 'authErrorGenericMessage',
      );
    }

    final cities = citiesResult.fold(
      (_) => throw StateError(''),
      (List<MarketCity> value) => value,
    );
    final bool cityPickerLocked = cities.length == 1;
    final MarketCity? selectedCity = cityPickerLocked ? cities.first : null;

    return current.copyWith(
      availableCities: cities,
      selectedCountry: country,
      selectedCity: selectedCity,
      isLoadingCities: false,
      cityPickerLocked: cityPickerLocked,
      draft: selectedCity == null
          ? current.draft
          : current.draft.copyWith(
              countryCode: country.countryCode,
              countryName: country.countryName,
              cityId: selectedCity.cityId,
              cityName: selectedCity.cityName,
              currencyCode: selectedCity.currencyCode,
              timezone: selectedCity.timezone,
            ),
    );
  }

  Map<String, String?> _clearFieldError(String key) {
    final Map<String, String?> next = Map<String, String?>.from(
      state.fieldErrors,
    );
    next.remove(key);
    return next;
  }

  Map<String, String?> _clearFieldErrors(List<String> keys) {
    final Map<String, String?> next = Map<String, String?>.from(
      state.fieldErrors,
    );
    for (final String key in keys) {
      next.remove(key);
    }
    return next;
  }
}
