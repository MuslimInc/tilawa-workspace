import 'package:equatable/equatable.dart';

sealed class HomeDashboardEvent extends Equatable {
  const HomeDashboardEvent();

  @override
  List<Object?> get props => const [];
}

final class HomeDashboardStarted extends HomeDashboardEvent {
  const HomeDashboardStarted();
}

final class HomeDashboardRefreshRequested extends HomeDashboardEvent {
  const HomeDashboardRefreshRequested();
}
