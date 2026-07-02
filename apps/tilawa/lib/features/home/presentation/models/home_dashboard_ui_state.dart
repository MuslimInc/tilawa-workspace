import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_dashboard_renderability.dart';
import '../bloc/home_dashboard_state.dart';

/// Presentation mapping for Home loading / content / error affordances.
enum HomeDashboardUiPhase {
  /// Cold load with no renderable dashboard — full hero + body skeleton.
  initialSkeleton,

  /// Renderable dashboard on screen (cache or fresh).
  content,

  /// Initial load failed with no renderable cache.
  failure,
}

final class HomeDashboardUiState {
  const HomeDashboardUiState({
    required this.phase,
    this.dashboard,
    this.failureIsOffline = false,
    this.refreshError,
    this.isRefreshingLocation = false,
  });

  final HomeDashboardUiPhase phase;
  final HomeDashboard? dashboard;
  final bool failureIsOffline;
  final HomeDashboardFailureKind? refreshError;
  final bool isRefreshingLocation;

  bool get showFullSkeleton => phase == HomeDashboardUiPhase.initialSkeleton;

  bool get showFailure => phase == HomeDashboardUiPhase.failure;

  bool get showContent => phase == HomeDashboardUiPhase.content;

  factory HomeDashboardUiState.from(HomeDashboardState state) {
    return switch (state) {
      HomeDashboardInitial() ||
      HomeDashboardLoading() => const HomeDashboardUiState(
        phase: HomeDashboardUiPhase.initialSkeleton,
      ),
      HomeDashboardLoaded(
        :final dashboard,
        :final refreshError,
        :final isRefreshingLocation,
      ) =>
        HomeDashboardUiState(
          phase: HomeDashboardUiPhase.content,
          dashboard: dashboard,
          refreshError: refreshError,
          isRefreshingLocation: isRefreshingLocation,
        ),
      HomeDashboardFailure(:final kind) => HomeDashboardUiState(
        phase: HomeDashboardUiPhase.failure,
        failureIsOffline: kind == HomeDashboardFailureKind.offline,
      ),
    };
  }

  /// Maps a bloc state to the dashboard snapshot widgets should render.
  static HomeDashboard? dashboardFor(HomeDashboardState state) {
    return switch (state) {
      HomeDashboardLoaded(:final dashboard) => dashboard,
      _ => null,
    };
  }

  /// Whether [state] should keep the full Home skeleton visible.
  static bool showsFullSkeleton(HomeDashboardState state) {
    return HomeDashboardUiState.from(state).showFullSkeleton;
  }

  /// Whether [state] has renderable content without entering skeleton mode.
  static bool hasRenderableContent(HomeDashboardState state) {
    final HomeDashboard? dashboard = dashboardFor(state);
    return dashboard != null && dashboard.isRenderable;
  }
}
