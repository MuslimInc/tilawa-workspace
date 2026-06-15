import 'package:equatable/equatable.dart';

sealed class HomeDashboardEvent extends Equatable {
  const HomeDashboardEvent();

  @override
  List<Object?> get props => const [];
}

final class HomeDashboardStarted extends HomeDashboardEvent {
  const HomeDashboardStarted({this.localeIdentifier});

  final String? localeIdentifier;

  @override
  List<Object?> get props => [localeIdentifier];
}

final class HomeDashboardRefreshRequested extends HomeDashboardEvent {
  const HomeDashboardRefreshRequested({this.localeIdentifier});

  final String? localeIdentifier;

  @override
  List<Object?> get props => [localeIdentifier];
}

final class HomeDashboardLocaleChanged extends HomeDashboardEvent {
  const HomeDashboardLocaleChanged({required this.localeIdentifier});

  final String localeIdentifier;

  @override
  List<Object?> get props => [localeIdentifier];
}

final class HomeDashboardLocationRefreshRequested extends HomeDashboardEvent {
  const HomeDashboardLocationRefreshRequested({this.localeIdentifier});

  final String? localeIdentifier;

  @override
  List<Object?> get props => [localeIdentifier];
}
