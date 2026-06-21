// ignore_for_file: prefer_initializing_formals
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/market_city.dart';
import '../../../domain/entities/market_country.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/usecases/complete_student_profile_usecase.dart';
import '../../../domain/usecases/get_market_config_usecase.dart';
import '../../../domain/usecases/get_session_policy_usecase.dart';
import '../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../utils/dob_validator.dart';
import 'profile_completion_event.dart';
import 'profile_completion_state.dart';

class ProfileCompletionBloc
    extends Bloc<ProfileCompletionEvent, ProfileCompletionState> {
  ProfileCompletionBloc({
    required GetUserProfileUseCase getUserProfile,
    required CompleteStudentProfileUseCase completeStudentProfile,
    required GetMarketConfigUseCase getMarketConfig,
    required GetSessionPolicyUseCase getSessionPolicy,
  }) : _getUserProfile = getUserProfile,
       _completeStudentProfile = completeStudentProfile,
       _getMarketConfig = getMarketConfig,
       _getSessionPolicy = getSessionPolicy,
       super(const ProfileCompletionInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested, transformer: restartable());
    on<GenderSelected>(_onGenderSelected, transformer: sequential());
    on<DateOfBirthSet>(_onDateOfBirthSet, transformer: sequential());
    on<CountrySelected>(_onCountrySelected, transformer: restartable());
    on<CitySelected>(_onCitySelected, transformer: sequential());
    on<ProfileSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetUserProfileUseCase _getUserProfile;
  final CompleteStudentProfileUseCase _completeStudentProfile;
  final GetMarketConfigUseCase _getMarketConfig;
  final GetSessionPolicyUseCase _getSessionPolicy;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileCompletionState> emit,
  ) async {
    emit(const ProfileCompletionLoading());

    final profileFuture = _getUserProfile(event.userId);
    final countriesFuture = _getMarketConfig.supportedCountries();
    final policyFuture = _getSessionPolicy();
    final profileResult = await profileFuture;
    final countriesResult = await countriesFuture;
    final policyResult = await policyFuture;

    if (profileResult.isLeft) {
      profileResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }
    if (countriesResult.isLeft) {
      countriesResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }
    if (policyResult.isLeft) {
      policyResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }

    final profile = profileResult.fold((_) => throw StateError(''), (p) => p);
    final countries = countriesResult.fold(
      (_) => throw StateError(''),
      (list) => list,
    );
    final policy = policyResult.fold((_) => throw StateError(''), (p) => p);

    final countryPickerLocked = countries.length == 1;
    MarketCountry? selectedCountry = _resolveInitialCountry(profile, countries);

    var editing = ProfileCompletionEditing(
      userId: event.userId,
      availableCountries: countries,
      minimumStudentAgeYears: policy.minimumStudentAgeYears,
      selectedGender: profile.gender,
      selectedDateOfBirth: profile.dateOfBirth,
      selectedCountry: selectedCountry,
      countryPickerLocked: countryPickerLocked,
      isLoadingCities: selectedCountry != null,
    );
    emit(editing);

    if (selectedCountry != null) {
      final citiesState = await _loadCitiesForCountry(
        editing,
        selectedCountry,
        preselectedCityId: profile.cityId,
      );
      if (!isClosed) emit(citiesState);
    }
  }

  MarketCountry? _resolveInitialCountry(
    UserProfile profile,
    List<MarketCountry> countries,
  ) {
    if (profile.countryCode != null) {
      return countries
          .where((c) => c.countryCode == profile.countryCode)
          .firstOrNull;
    }
    if (countries.length == 1) return countries.first;
    return null;
  }

  Future<ProfileCompletionState> _loadCitiesForCountry(
    ProfileCompletionEditing current,
    MarketCountry country, {
    String? preselectedCityId,
  }) async {
    final citiesResult = await _getMarketConfig.citiesByCountry(
      country.countryCode,
    );
    if (citiesResult.isLeft) {
      return ProfileCompletionFailure(
        citiesResult.fold((f) => f, (_) => throw StateError('')),
      );
    }
    final cities = citiesResult.fold((_) => throw StateError(''), (c) => c);
    final cityPickerLocked = cities.length == 1;
    MarketCity? selectedCity;
    if (preselectedCityId != null) {
      selectedCity = cities
          .where((c) => c.cityId == preselectedCityId)
          .firstOrNull;
    }
    selectedCity ??= cityPickerLocked ? cities.firstOrNull : null;

    return current.copyWith(
      availableCities: cities,
      selectedCountry: country,
      selectedCity: selectedCity,
      isLoadingCities: false,
      cityPickerLocked: cityPickerLocked,
    );
  }

  void _onGenderSelected(
    GenderSelected event,
    Emitter<ProfileCompletionState> emit,
  ) {
    final current = state;
    if (current is! ProfileCompletionEditing) return;
    emit(
      current.copyWith(
        selectedGender: event.gender,
      ),
    );
  }

  void _onDateOfBirthSet(
    DateOfBirthSet event,
    Emitter<ProfileCompletionState> emit,
  ) {
    final current = state;
    if (current is! ProfileCompletionEditing) return;
    final failure = DobValidator.validate(
      event.dateOfBirth,
      minimumAgeYears: current.minimumStudentAgeYears,
    );
    if (failure != null) {
      emit(current.copyWith(clearDob: true, dobFailure: failure));
      return;
    }
    emit(
      current.copyWith(
        selectedDateOfBirth: event.dateOfBirth,
        clearDobFailure: true,
      ),
    );
  }

  Future<void> _onCountrySelected(
    CountrySelected event,
    Emitter<ProfileCompletionState> emit,
  ) async {
    final current = state;
    if (current is! ProfileCompletionEditing) return;

    emit(
      current.copyWith(
        selectedCountry: event.country,
        clearCity: true,
        availableCities: const [],
        isLoadingCities: true,
        cityPickerLocked: false,
      ),
    );

    final updated = await _loadCitiesForCountry(
      current.copyWith(
        selectedCountry: event.country,
        clearCity: true,
        isLoadingCities: true,
      ),
      event.country,
    );
    emit(updated);
  }

  void _onCitySelected(
    CitySelected event,
    Emitter<ProfileCompletionState> emit,
  ) {
    final current = state;
    if (current is! ProfileCompletionEditing) return;
    emit(current.copyWith(selectedCity: event.city));
  }

  Future<void> _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileCompletionState> emit,
  ) async {
    final current = state;
    if (current is! ProfileCompletionEditing) return;

    final validated = current.applySubmitValidation();
    if (!validated.canSubmit) {
      emit(validated);
      return;
    }

    emit(const ProfileCompletionSaving());

    final country = current.selectedCountry!;
    final city = current.selectedCity!;

    final result = await _completeStudentProfile(
      userId: event.userId,
      gender: current.selectedGender!,
      dateOfBirth: current.selectedDateOfBirth!,
      countryCode: country.countryCode,
      countryName: country.countryName,
      cityId: city.cityId,
      cityName: city.cityName,
      currencyCode: city.currencyCode,
      timezone: city.timezone,
    );

    result.fold(
      (failure) => emit(ProfileCompletionFailure(failure)),
      (profile) => emit(ProfileCompletionSaved(profile)),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
