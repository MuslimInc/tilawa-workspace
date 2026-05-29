// Snapshot + spike helpers remain for tests. Route progress bridge types are
// legacy — [PlayerPresentationController] owns ticks in production.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:tilawa/shared/widgets/quran_player_debug_log.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';

/// Visual + interaction snapshot for shell-footer Hero expansion.
///
/// Keeps route animation, footer layout, and debug fields aligned so Hero mode
/// does not rely on a forced [AnimationController] value of 0 or 1.
@immutable
class QuranPlayerHeroExpansionSnapshot {
  const QuranPlayerHeroExpansionSnapshot({
    required this.routeOpen,
    required this.routeProgress,
    required this.controllerProgress,
    required this.isCollapsing,
    required this.isDragging,
    required this.usesHeroExpansion,
  });

  final bool routeOpen;
  final double routeProgress;
  final double controllerProgress;
  final bool isCollapsing;
  final bool isDragging;
  final bool usesHeroExpansion;

  /// Progress that drives cross-fades and layout metrics in Hero mode.
  double get visualProgress =>
      usesHeroExpansion ? (routeOpen ? routeProgress : 0.0) : controllerProgress;

  bool get isExpandedSettled => visualProgress >= 0.99;

  bool get isMiniSettled => visualProgress <= 0.01;

  bool get isTransitioning =>
      usesHeroExpansion &&
      routeOpen &&
      routeProgress > 0.001 &&
      routeProgress < 0.99;

  /// Who owns the active transition animation.
  String get transitionOwner {
    if (!usesHeroExpansion) {
      return 'expandController';
    }
    if (routeOpen && routeProgress < 0.99) {
      return 'heroRoute';
    }
    if (routeOpen) {
      return 'heroRouteSettled';
    }
    if (routeProgress > 0.001) {
      return 'heroRouteClosing';
    }
    return 'footerMini';
  }

  String get renderTree {
    if (!usesHeroExpansion) {
      return routeOpen ? 'overlay' : 'footerMini';
    }
    if (routeOpen) {
      return isExpandedSettled ? 'heroExpandedPage' : 'heroTransition';
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

/// Legacy route progress notifier — superseded by [PlayerPresentationController].
@Deprecated('Use PlayerPresentationController.onRouteAnimationTick')
class QuranPlayerHeroRouteProgress extends ChangeNotifier {
  QuranPlayerHeroRouteProgress();

  double _value = 0;

  double get value => _value;

  bool get routeOpen => _routeOpen;
  bool _routeOpen = false;

  void beginRoute() {
    _routeOpen = true;
    _value = 0;
    notifyListeners();
  }

  void tick(double progress) {
    final double clamped = progress.clamp(0.0, 1.0);
    if (_value == clamped && _routeOpen) {
      return;
    }
    _routeOpen = true;
    _value = clamped;
    notifyListeners();
  }

  void endRoute() {
    _routeOpen = false;
    _value = 0;
    notifyListeners();
  }

  QuranPlayerHeroExpansionSnapshot snapshot({
    required double controllerProgress,
    required bool isCollapsing,
    required bool isDragging,
    required bool usesHeroExpansion,
  }) {
    return QuranPlayerHeroExpansionSnapshot(
      routeOpen: _routeOpen,
      routeProgress: _value,
      controllerProgress: controllerProgress,
      isCollapsing: isCollapsing,
      isDragging: isDragging,
      usesHeroExpansion: usesHeroExpansion,
    );
  }
}

@Deprecated('Use QuranPlayerExpandedPage route listener')
class QuranPlayerHeroRouteProgressBridge extends StatefulWidget {
  const QuranPlayerHeroRouteProgressBridge({
    super.key,
    required this.progress,
    required this.animation,
    required this.child,
  });

  final QuranPlayerHeroRouteProgress progress;
  final Animation<double> animation;
  final Widget child;

  @override
  State<QuranPlayerHeroRouteProgressBridge> createState() =>
      _QuranPlayerHeroRouteProgressBridgeState();
}

class _QuranPlayerHeroRouteProgressBridgeState
    extends State<QuranPlayerHeroRouteProgressBridge> {
  bool _seenForward = false;
  bool _seenReverse = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _seenForward = true;
    }
    if (status == AnimationStatus.reverse) {
      _seenReverse = true;
    }
    _sync();
  }

  void _sync() {
    final Animation<double> anim = widget.animation;
    final double value = anim.value.clamp(0.0, 1.0);
    final AnimationStatus status = anim.status;

    final bool spuriousPushComplete =
        !_seenForward &&
        !_seenReverse &&
        status == AnimationStatus.completed &&
        value >= 0.99 &&
        widget.progress.value <= 0.05;

    if (spuriousPushComplete) {
      QuranPlayerDebugLog.hero(
        'route.progress.spikeIgnored',
        <String, Object?>{
          'value': value.toStringAsFixed(3),
          'status': status.name,
        },
      );
      return;
    }

    widget.progress.tick(value);
  }

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_sync);
    widget.animation.addStatusListener(_onStatus);
    _sync();
  }

  @override
  void didUpdateWidget(covariant QuranPlayerHeroRouteProgressBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_sync);
      oldWidget.animation.removeStatusListener(_onStatus);
      _seenForward = false;
      _seenReverse = false;
      widget.animation.addListener(_sync);
      widget.animation.addStatusListener(_onStatus);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_sync);
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Returns true when a route animation reports completed@1.0 before forward.
@visibleForTesting
bool isSpuriousHeroRouteProgressSpike({
  required bool seenForward,
  required bool seenReverse,
  required AnimationStatus status,
  required double value,
  required double currentProgress,
}) {
  return !seenForward &&
      !seenReverse &&
      status == AnimationStatus.completed &&
      value >= 0.99 &&
      currentProgress <= 0.05;
}
