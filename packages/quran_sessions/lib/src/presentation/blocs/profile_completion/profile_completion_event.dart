import 'package:equatable/equatable.dart';

import '../../../domain/entities/market_city.dart';
import '../../../domain/entities/market_country.dart';
import '../../../domain/entities/user_profile.dart';

sealed class ProfileCompletionEvent extends Equatable {
  const ProfileCompletionEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted — load profile, countries, and policy.
final class ProfileLoadRequested extends ProfileCompletionEvent {
  const ProfileLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class GenderSelected extends ProfileCompletionEvent {
  const GenderSelected(this.gender);

  final UserGender gender;

  @override
  List<Object?> get props => [gender];
}

final class DateOfBirthSet extends ProfileCompletionEvent {
  const DateOfBirthSet(this.dateOfBirth);

  final DateTime dateOfBirth;

  @override
  List<Object?> get props => [dateOfBirth];
}

/// User selects a country — loads that country's cities from the backend.
final class CountrySelected extends ProfileCompletionEvent {
  const CountrySelected(this.country);

  final MarketCountry country;

  @override
  List<Object?> get props => [country];
}

final class CitySelected extends ProfileCompletionEvent {
  const CitySelected(this.city);

  final MarketCity city;

  @override
  List<Object?> get props => [city];
}

final class LearningGoalToggled extends ProfileCompletionEvent {
  const LearningGoalToggled(this.goal);

  final StudentLearningGoal goal;

  @override
  List<Object?> get props => [goal];
}

final class ProfileSubmitted extends ProfileCompletionEvent {
  const ProfileSubmitted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
