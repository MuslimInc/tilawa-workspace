import 'package:meta/meta.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

export 'package:tilawa/shared/widgets/quran_player_route_progress_guard.dart'
    show isSpuriousRouteProgressSpike;

/// Visual + interaction snapshot for player transition tests.
///
/// Production uses [PlayerPresentationController]; this type supports unit
/// tests that assert metric curves without a full widget tree.
@immutable
class QuranPlayerExpansionSnapshot {
  const QuranPlayerExpansionSnapshot({
    required this.routeOpen,
    required this.routeProgress,
    required this.controllerProgress,
    required this.isCollapsing,
    required this.isDragging,
    required this.usesRouteExpansion,
  });

  final bool routeOpen;
  final double routeProgress;
  final double controllerProgress;
  final bool isCollapsing;
  final bool isDragging;

  /// When true, [visualProgress] follows [routeProgress] while [routeOpen].
  final bool usesRouteExpansion;

  double get visualProgress => usesRouteExpansion
      ? (routeOpen ? routeProgress : 0.0)
      : controllerProgress;

  bool get isExpandedSettled => visualProgress >= 0.99;

  bool get isMiniSettled => visualProgress <= 0.01;

  bool get isTransitioning =>
      usesRouteExpansion &&
      routeOpen &&
      routeProgress > 0.001 &&
      routeProgress < 0.99;

  String get transitionOwner {
    if (!usesRouteExpansion) {
      return 'expandController';
    }
    if (routeOpen && routeProgress < 0.99) {
      return 'route';
    }
    if (routeOpen) {
      return 'routeSettled';
    }
    if (routeProgress > 0.001) {
      return 'routeClosing';
    }
    return 'footerMini';
  }

  String get renderTree {
    if (!usesRouteExpansion) {
      return routeOpen ? 'overlay' : 'footerMini';
    }
    if (routeOpen) {
      return isExpandedSettled ? 'routeExpanded' : 'routeTransition';
    }
    return isTransitioning ? 'footerMiniTransition' : 'footerMini';
  }

  PlayerExpandTransitionMetrics metrics({
    required double miniPlayerHeight,
    required bool collapseBiased,
    bool heroHandoff = false,
  }) {
    return PlayerExpandTransitionMetrics.compute(
      progress: visualProgress,
      miniPlayerHeight: miniPlayerHeight,
      collapseBiased: collapseBiased,
      heroHandoff: heroHandoff,
    );
  }
}
