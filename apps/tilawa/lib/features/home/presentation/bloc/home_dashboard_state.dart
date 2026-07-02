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
  const HomeDashboardLoaded(
    this.dashboard, {
    this.isRefreshingLocation = false,
    this.isRefreshing = false,
    this.refreshErrorMessage,
  });

  final HomeDashboard dashboard;
  final bool isRefreshingLocation;
  final bool isRefreshing;

  /// Raw error from the last pull-to-refresh attempt; surfaced once in UI.
  final String? refreshErrorMessage;

  HomeDashboardLoaded copyWith({
    HomeDashboard? dashboard,
    bool? isRefreshingLocation,
    bool? isRefreshing,
    String? refreshErrorMessage,
    bool clearRefreshErrorMessage = false,
  }) {
    return HomeDashboardLoaded(
      dashboard ?? this.dashboard,
      isRefreshingLocation: isRefreshingLocation ?? this.isRefreshingLocation,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshErrorMessage: clearRefreshErrorMessage
          ? null
          : refreshErrorMessage ?? this.refreshErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    dashboard,
    isRefreshingLocation,
    isRefreshing,
    refreshErrorMessage,
  ];
}

final class HomeDashboardFailure extends HomeDashboardState {
  const HomeDashboardFailure(
    this.message, {
    this.kind = HomeDashboardFailureKind.generic,
  });

  final String message;
  final HomeDashboardFailureKind kind;

  @override
  List<Object?> get props => [message, kind];
}

enum HomeDashboardFailureKind {
  offline,
  generic,
}
