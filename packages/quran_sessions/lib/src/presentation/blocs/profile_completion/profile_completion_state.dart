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
    this.selectedGender,
    this.selectedDateOfBirth,
    this.selectedMarket,
    this.selectedCity,
  });

  final String userId;

  /// All supported markets — used to populate the country picker.
  final List<MarketConfig> availableMarkets;

  final UserGender? selectedGender;
  final DateTime? selectedDateOfBirth;

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
      selectedMarket != null &&
      selectedCity != null;

  ProfileCompletionEditing copyWith({
    UserGender? selectedGender,
    DateTime? selectedDateOfBirth,
    MarketConfig? selectedMarket,
    CityConfig? selectedCity,
    bool clearCity = false,
  }) => ProfileCompletionEditing(
    userId: userId,
    availableMarkets: availableMarkets,
    selectedGender: selectedGender ?? this.selectedGender,
    selectedDateOfBirth: selectedDateOfBirth ?? this.selectedDateOfBirth,
    selectedMarket: selectedMarket ?? this.selectedMarket,
    selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
  );

  @override
  List<Object?> get props => [
    userId,
    availableMarkets,
    selectedGender,
    selectedDateOfBirth,
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
