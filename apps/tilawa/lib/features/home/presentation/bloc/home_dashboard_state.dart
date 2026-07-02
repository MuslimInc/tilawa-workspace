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
    this.refreshError,
  });

  final HomeDashboard dashboard;
  final bool isRefreshingLocation;
  final bool isRefreshing;

  /// Classified error of the last pull-to-refresh attempt; surfaced once in
  /// UI as localized copy. Raw error details stay in logs.
  final HomeDashboardFailureKind? refreshError;

  HomeDashboardLoaded copyWith({
    HomeDashboard? dashboard,
    bool? isRefreshingLocation,
    bool? isRefreshing,
    HomeDashboardFailureKind? refreshError,
    bool clearRefreshError = false,
  }) {
    return HomeDashboardLoaded(
      dashboard ?? this.dashboard,
      isRefreshingLocation: isRefreshingLocation ?? this.isRefreshingLocation,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearRefreshError
          ? null
          : refreshError ?? this.refreshError,
    );
  }

  @override
  List<Object?> get props => [
    dashboard,
    isRefreshingLocation,
    isRefreshing,
    refreshError,
  ];
}

final class HomeDashboardFailure extends HomeDashboardState {
  const HomeDashboardFailure(this.kind);

  final HomeDashboardFailureKind kind;

  @override
  List<Object?> get props => [kind];
}

/// Classified dashboard failure causes; UI maps these to localized copy.
enum HomeDashboardFailureKind {
  offline,
  timeout,

  /// Reserved for typed server failures once the repository returns
  /// `Either<Failure, T>` (Phase 2).
  server,

  /// Reserved for location-refresh failures once they surface in UI.
  location,
  unknown,
}
