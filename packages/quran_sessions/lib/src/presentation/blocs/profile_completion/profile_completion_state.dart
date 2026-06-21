import 'package:equatable/equatable.dart';

import '../../../domain/entities/market_config.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

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

  /// Cities available for selection in the current [selectedMarket].
  List<CityConfig> get availableCities =>
      selectedMarket?.enabledCities ?? const [];

  bool get canSubmit =>
      selectedGender != null &&
      selectedDateOfBirth != null &&
      dobFailure == null &&
      selectedMarket != null &&
      selectedCity != null;

  ProfileCompletionEditing copyWith({
    UserGender? selectedGender,
    DateTime? selectedDateOfBirth,
    QuranSessionsFailure? dobFailure,
    bool clearDob = false,
    bool clearDobFailure = false,
    MarketConfig? selectedMarket,
    CityConfig? selectedCity,
    bool clearCity = false,
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
