// ignore_for_file: prefer_initializing_formals
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/market_config.dart';
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
    on<CountrySelected>(_onCountrySelected, transformer: sequential());
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

    // Load profile, available markets, and the (remote-config-backed) safety
    // policy in parallel.
    final profileFuture = _getUserProfile(event.userId);
    final marketsFuture = _getMarketConfig.allMarkets();
    final policyFuture = _getSessionPolicy();
    final profileResult = await profileFuture;
    final marketsResult = await marketsFuture;
    final policyResult = await policyFuture;

    if (profileResult.isLeft) {
      profileResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }
    if (marketsResult.isLeft) {
      marketsResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }
    if (policyResult.isLeft) {
      policyResult.fold((f) => emit(ProfileCompletionFailure(f)), (_) {});
      return;
    }

    final profile = profileResult.fold((_) => throw StateError(''), (p) => p);
    final markets = marketsResult.fold(
      (_) => throw StateError(''),
      (ms) => ms,
    );
    final policy = policyResult.fold((_) => throw StateError(''), (p) => p);

    // Pre-select country/city if the profile already has them.
    // For new profiles, auto-suggest the only enabled market (MVP: Egypt) as a
    // convenience — the user still must explicitly pick a city and submit.
    MarketConfig? preSelectedMarket;
    CityConfig? preSelectedCity;
    if (profile.countryCode != null) {
      preSelectedMarket = markets
          .where((m) => m.countryCode == profile.countryCode)
          .firstOrNull;
      if (preSelectedMarket != null && profile.cityId != null) {
        preSelectedCity = preSelectedMarket.cityById(profile.cityId!);
      }
    } else {
      final enabledMarkets = markets.where((m) => m.isEnabled).toList();
      if (enabledMarkets.length == 1) {
        preSelectedMarket = enabledMarkets.first;
      }
    }

    emit(
      ProfileCompletionEditing(
        userId: event.userId,
        availableMarkets: markets,
        minimumStudentAgeYears: policy.minimumStudentAgeYears,
        selectedGender: profile.gender,
        selectedDateOfBirth: profile.dateOfBirth,
        selectedMarket: preSelectedMarket,
        selectedCity: preSelectedCity,
      ),
    );
  }

  void _onGenderSelected(
    GenderSelected event,
    Emitter<ProfileCompletionState> emit,
  ) {
    final current = state;
    if (current is! ProfileCompletionEditing) return;
    emit(current.copyWith(selectedGender: event.gender));
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
      // Clear the stored DOB and record the failure so the UI can show it.
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

  void _onCountrySelected(
    CountrySelected event,
    Emitter<ProfileCompletionState> emit,
  ) {
    final current = state;
    if (current is! ProfileCompletionEditing) return;
    // Changing country clears the city selection.
    emit(
      current.copyWith(selectedMarket: event.market, clearCity: true),
    );
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
    if (!current.canSubmit) return;

    emit(const ProfileCompletionSaving());

    final result = await _completeStudentProfile(
      userId: event.userId,
      gender: current.selectedGender!,
      dateOfBirth: current.selectedDateOfBirth!,
      countryCode: current.selectedMarket!.countryCode,
      countryName: current.selectedMarket!.countryName,
      cityId: current.selectedCity!.cityId,
      cityName: current.selectedCity!.cityName,
      currencyCode: current.selectedCity!.currencyCode,
      timezone: current.selectedCity!.timezone,
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
