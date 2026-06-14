import 'package:equatable/equatable.dart';

import '../../domain/entities/home_dashboard.dart';

sealed class HomeDashboardState extends Equatable {
  const HomeDashboardState();

  @override
  List<Object?> get props => const [];
}

final class HomeDashboardInitial extends HomeDashboardState {
  const HomeDashboardInitial();
}

final class HomeDashboardLoading extends HomeDashboardState {
  const HomeDashboardLoading();
}

final class HomeDashboardLoaded extends HomeDashboardState {
  const HomeDashboardLoaded(this.dashboard);

  final HomeDashboard dashboard;

  @override
  List<Object?> get props => [dashboard];
}

final class HomeDashboardFailure extends HomeDashboardState {
  const HomeDashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
