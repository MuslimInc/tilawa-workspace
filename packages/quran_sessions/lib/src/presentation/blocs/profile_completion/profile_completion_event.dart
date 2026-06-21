import 'package:equatable/equatable.dart';

import '../../../domain/entities/market_config.dart';
import '../../../domain/entities/user_profile.dart';

sealed class ProfileCompletionEvent extends Equatable {
  const ProfileCompletionEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted — load the current profile state and available markets.
final class ProfileLoadRequested extends ProfileCompletionEvent {
  const ProfileLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// User picks their gender.
final class GenderSelected extends ProfileCompletionEvent {
  const GenderSelected(this.gender);

  final UserGender gender;

  @override
  List<Object?> get props => [gender];
}

/// User sets their date of birth.
final class DateOfBirthSet extends ProfileCompletionEvent {
  const DateOfBirthSet(this.dateOfBirth);

  final DateTime dateOfBirth;

  @override
  List<Object?> get props => [dateOfBirth];
}

/// User selects a country — triggers loading of that country's city list.
final class CountrySelected extends ProfileCompletionEvent {
  const CountrySelected(this.market);

  final MarketConfig market;

  @override
  List<Object?> get props => [market];
}

/// User selects a city within the previously selected country.
final class CitySelected extends ProfileCompletionEvent {
  const CitySelected(this.city);

  final CityConfig city;

  @override
  List<Object?> get props => [city];
}

/// User taps "Save" — persist all collected fields.
final class ProfileSubmitted extends ProfileCompletionEvent {
  const ProfileSubmitted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
