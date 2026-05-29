import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/shared/widgets/quran_player_debug_log.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_system_back.dart';

import 'player_presentation_phase.dart';
import 'quran_player_navigation.dart';
import 'quran_player_presentation_entry.dart';

/// Presentation authority for the Quran player (not playback, not chrome publish).
///
/// Owns: [PlayerPresentationPhase], route-driven [transitionProgress], expand/
/// collapse lifecycle, hero expanded gestures, system-back intercept flag.
///
/// Does **not** own: [AudioPlayerBloc], queue/transport, [BuildContext],
/// [QuranPlayerChromeNotifier] writes, or layout widgets.
///
/// External entry must use [QuranPlayerPresentationEntry.openExpanded] after the
/// bloc has media — never push `/player` from feature code directly.
///
/// Vocabulary: `docs/architecture/media-state-vocabulary.md`
/// Boundaries: `docs/architecture/player-presentation.md`
@lazySingleton
class PlayerPresentationController extends ChangeNotifier {
  PlayerPresentationController(this._navigation);

  final QuranPlayerNavigation _navigation;

  PlayerPresentationPhase _phase = PlayerPresentationPhase.mini;
  double _transitionProgress = 0;
  bool _routeOpen = false;
  bool _isDragging = false;
  bool _collapseBiased = false;
  bool _collapseRequested = false;
  bool _seenForwardAnimation = false;
  bool _seenReverseAnimation = false;

  double _expandDragNetDy = 0;

  VoidCallback? _systemBackHandle;
  VoidCallback? _dismissPlayerHandle;

  Future<void>? _expandInFlight;

  bool _notifyScheduled = false;

  PlayerPresentationPhase get phase => _phase;

  double get transitionProgress => _transitionProgress;

  bool get routeOpen => _routeOpen;

  bool get isDragging => _isDragging;

  bool get usesHeroShellFooter => true;

  /// Progress that drives footer cross-fades and debug snapshots.
  ///
  /// Stays on the route curve until the reverse animation reaches zero — not
  /// when the GoRouter pop future completes.
  double get visualProgress {
    if (_phase == PlayerPresentationPhase.mini &&
        _transitionProgress <= 0.001) {
      return 0;
    }
    return _transitionProgress;
  }

  bool get isExpandedSettled =>
      _routeOpen && _transitionProgress >= 0.99 && _phase == PlayerPresentationPhase.expanded;

  bool get isMiniSettled => !_routeOpen && _transitionProgress <= 0.01;

  bool get overlayChromeActive =>
      _routeOpen || _transitionProgress > 0.01;

  String get transitionOwner {
    if (!_routeOpen && _transitionProgress <= 0.001) {
      return 'footerMini';
    }
    if (_routeOpen && _transitionProgress < 0.99) {
      return 'heroRoute';
    }
    if (_routeOpen) {
      return 'heroRouteSettled';
    }
    if (_transitionProgress > 0.001) {
      return 'heroRouteClosing';
    }
    return 'footerMini';
  }

  String get renderTree {
    if (!_routeOpen) {
      return _transitionProgress > 0.001
          ? 'footerMiniTransition'
          : 'footerMini';
    }
    return isExpandedSettled ? 'heroExpandedPage' : 'heroTransition';
  }

  String get visualMode => QuranPlayerDebugLog.playerMode(
    expandProgress: visualProgress,
    isCollapsing: _phase == PlayerPresentationPhase.collapsing,
    isUserDragging: _isDragging,
    transitionOwner: transitionOwner,
  );

  /// Binds system-back handling for the active player widget instance.
  void bindSystemBack({required VoidCallback handle}) {
    _systemBackHandle = handle;
    _syncSystemBackIntercepts();
  }

  void unbindSystemBack({required VoidCallback handle}) {
    if (!identical(_systemBackHandle, handle)) {
      return;
    }
    _systemBackHandle = null;
    QuranPlayerSystemBackCoordinator.unbind(handle: handle);
  }

  void bindDismissPlayer({required VoidCallback handle}) {
    _dismissPlayerHandle = handle;
  }

  void unbindDismissPlayer({required VoidCallback handle}) {
    if (identical(_dismissPlayerHandle, handle)) {
      _dismissPlayerHandle = null;
    }
  }

  void dismissPlayer() => _dismissPlayerHandle?.call();

  void setInterceptsAllowed(bool allowed) {
    if (!allowed) {
      QuranPlayerSystemBackCoordinator.setIntercepts(false);
      return;
    }
    _syncSystemBackIntercepts();
  }

  /// Opens the typed `/player` overlay route.
  Future<void> expand() async {
    if (_expandInFlight != null) {
      await _expandInFlight!;
      // #region agent log
      QuranPlayerDebugLog.agent(
        hypothesisId: 'IF',
        location: 'player_presentation_controller.dart:expand',
        message: 'expand resumed after in-flight session',
        data: <String, Object?>{
          'onStack': _navigation.isExpandedRouteOnStack,
          'phase': _phase.name,
          'routeOpen': _routeOpen,
          'transitionProgress': _transitionProgress.toStringAsFixed(3),
          'collapseRequested': _collapseRequested,
        },
      );
      // #endregion
      // Coalesced callers joined an existing session; never start another.
      return;
    }

    if (_navigation.isExpandedRouteOnStack &&
        (_phase == PlayerPresentationPhase.expanded ||
            (_phase == PlayerPresentationPhase.expanding &&
                _transitionProgress >= 0.5))) {
      _routeOpen = true;
      return;
    }

    if (_routeOpen && !_navigation.isExpandedRouteOnStack) {
      _onRouteClosed(silent: true);
    }

    final Future<void> session = _expandAndAwaitPop();
    _expandInFlight = session;
    try {
      await session;
    } finally {
      if (identical(_expandInFlight, session)) {
        _expandInFlight = null;
      }
    }
  }

  Future<void> _expandAndAwaitPop() async {
    _collapseBiased = false;
    _phase = PlayerPresentationPhase.expanding;
    _routeOpen = true;
    _transitionProgress = 0;
    _seenForwardAnimation = false;
    _seenReverseAnimation = false;
    // #region agent log
    QuranPlayerDebugLog.agentResetThrottle();
    // #endregion
    _notifyAndLog('expand.start');
    _syncSystemBackIntercepts();
    await _navigation.pushExpanded();
    if (_transitionProgress <= 0.01) {
      _onRouteClosed();
    }
  }

  /// Pops the overlay route when open.
  void collapse() {
    if (!_routeOpen && !_navigation.isExpandedRouteOnStack) {
      return;
    }
    _collapseBiased = true;
    _collapseRequested = true;
    _phase = PlayerPresentationPhase.collapsing;
    _routeOpen = true;
    _isDragging = false;
    _notifyAndLog('collapse.start');
    _navigation.popExpanded();
  }

  /// Called from the expanded page when the route animation ticks.
  void onRouteAnimationTick(double value, AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _seenForwardAnimation = true;
    }
    if (status == AnimationStatus.reverse) {
      _seenReverseAnimation = true;
    }

    if (_shouldIgnoreSpuriousCompletedFrame(value, status)) {
      QuranPlayerDebugLog.hero(
        'route.progress.spikeIgnored',
        <String, Object?>{
          'value': value.toStringAsFixed(3),
          'status': status.name,
        },
      );
      // #region agent log
      QuranPlayerDebugLog.agent(
        hypothesisId: 'E',
        location:
            'player_presentation_controller.dart:onRouteAnimationTick',
        message: 'spurious completed frame ignored',
        data: <String, Object?>{
          'value': value.toStringAsFixed(3),
          'status': status.name,
          'transitionProgress': _transitionProgress.toStringAsFixed(3),
        },
      );
      // #endregion
      return;
    }

    _transitionProgress = value.clamp(0.0, 1.0);
    _phase = _phaseForAnimationStatus(status, value);

    // #region agent log
    final double curved = QuranPlayerDebugLog.curvedRouteProgress(
      _transitionProgress,
      status,
    );
    final PlayerExpandTransitionMetrics metrics =
        PlayerExpandTransitionMetrics.compute(
      progress: _transitionProgress,
      miniPlayerHeight: 72,
      collapseBiased: _collapseBiased,
      heroHandoff:
          routeOpen && _phase != PlayerPresentationPhase.mini,
    );
    QuranPlayerDebugLog.agent(
      hypothesisId: 'C',
      location: 'player_presentation_controller.dart:onRouteAnimationTick',
      message: 'route progress tick',
      throttleProgress: true,
      progress: _transitionProgress,
      data: <String, Object?>{
        'raw': _transitionProgress.toStringAsFixed(3),
        'curved': curved.toStringAsFixed(3),
        'rawCurvedDelta': (curved - _transitionProgress).toStringAsFixed(3),
        'status': status.name,
        'phase': _phase.name,
        'handoffT': metrics.handoffT.toStringAsFixed(3),
        'showMorphLayer': metrics.showMorphLayer,
        'miniOpacity': metrics.miniOpacity.toStringAsFixed(3),
        'expandedOpacity': metrics.expandedOpacity.toStringAsFixed(3),
        'stageChromeOpacity': metrics.stageChromeOpacity.toStringAsFixed(3),
      },
    );
    QuranPlayerDebugLog.maybeWarnTransitionGap(
      progress: _transitionProgress,
      miniOpacity: metrics.miniOpacity,
      expandedOpacity: metrics.expandedOpacity,
      source: 'controller.tick',
    );
    // #endregion

    if (_transitionProgress <= 0.01 &&
        (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed)) {
      _onRouteClosed();
      return;
    }

    _scheduleNotifyListeners();
  }

  /// Called when the expanded page mounts.
  void onRouteOpened() {
    if (_phase == PlayerPresentationPhase.mini) {
      _phase = PlayerPresentationPhase.expanding;
    }
    _routeOpen = true;
    _notifyAndLog('route.opened');
    _syncSystemBackIntercepts();
  }

  /// Resets presentation when `/player` leaves the stack.
  void onRouteClosed() => _onRouteClosed();

  /// Syncs presentation when GoRouter no longer has `/player` (hot reload,
  /// external pop). Does not pop or push the route.
  void reconcileWithNavigationStack() {
    if (_collapseRequested ||
        _phase == PlayerPresentationPhase.collapsing) {
      return;
    }
    if (_routeOpen && !_navigation.isExpandedRouteOnStack) {
      _onRouteClosed(silent: true);
    }
  }

  /// True when `/player` was lost without a user collapse (e.g. hot reload).
  bool get shouldRestoreExpandedRoute =>
      !_collapseRequested &&
      !_navigation.isExpandedRouteOnStack &&
      (_phase == PlayerPresentationPhase.expanded ||
          (_phase == PlayerPresentationPhase.expanding &&
              _transitionProgress >= 0.5));

  void onHeroExpandedDragStart() {
    _expandDragNetDy = 0;
    _isDragging = true;
    QuranPlayerDebugLog.drag('heroExpanded.start', snapshot());
  }

  void onHeroExpandedDragUpdate(double dragPixels) {
    _expandDragNetDy += dragPixels;
  }

  void onHeroExpandedDragEnd({
    required double primaryVelocity,
    required double progressThreshold,
    required double velocityThreshold,
  }) {
    _isDragging = false;
    final PlayerExpandSnapTarget target = QuranPlayerExpandPhysics.resolveSnap(
      progress: 1,
      primaryVelocity: primaryVelocity,
      progressThreshold: progressThreshold,
      velocityThreshold: velocityThreshold,
      netDragDy: _expandDragNetDy,
    );
    _expandDragNetDy = 0;
    QuranPlayerDebugLog.drag(
      'heroExpanded.end',
      <String, Object?>{
        'snap': target.name,
        'primaryVelocity': primaryVelocity.toStringAsFixed(1),
        ...snapshot(),
      },
    );
    if (target == PlayerExpandSnapTarget.collapse) {
      collapse();
    }
  }

  PlayerExpandTransitionMetrics metricsForFooter({
    required double miniPlayerHeight,
  }) {
    return PlayerExpandTransitionMetrics.compute(
      progress: visualProgress,
      miniPlayerHeight: miniPlayerHeight,
      collapseBiased: _collapseBiased,
      heroHandoff:
          routeOpen && _phase != PlayerPresentationPhase.mini,
    );
  }

  Map<String, Object?> snapshot() {
    return <String, Object?>{
      'visualMode': visualMode,
      'phase': _phase.name,
      'visualProgress': visualProgress.toStringAsFixed(3),
      'transitionProgress': _transitionProgress.toStringAsFixed(3),
      'transitionOwner': transitionOwner,
      'renderTree': renderTree,
      'routeOpen': _routeOpen,
      'isDragging': _isDragging,
      'isCollapsing': _phase == PlayerPresentationPhase.collapsing,
      'collapseBiased': _collapseBiased,
    };
  }

  void _onRouteClosed({bool silent = false}) {
    if (_phase == PlayerPresentationPhase.mini &&
        _transitionProgress <= 0.001 &&
        !_routeOpen) {
      return;
    }
    _routeOpen = false;
    _transitionProgress = 0;
    _phase = PlayerPresentationPhase.mini;
    _isDragging = false;
    _collapseBiased = false;
    _collapseRequested = false;
    _seenForwardAnimation = false;
    _seenReverseAnimation = false;
    if (silent) {
      _scheduleNotifyListeners();
    } else {
      _notifyAndLog('route.closed');
    }
    _syncSystemBackIntercepts();
  }

  PlayerPresentationPhase _phaseForAnimationStatus(
    AnimationStatus status,
    double value,
  ) {
    if (status == AnimationStatus.reverse ||
        _phase == PlayerPresentationPhase.collapsing) {
      return PlayerPresentationPhase.collapsing;
    }
    if (value >= 0.99 && status == AnimationStatus.completed) {
      return PlayerPresentationPhase.expanded;
    }
    return PlayerPresentationPhase.expanding;
  }

  bool _shouldIgnoreSpuriousCompletedFrame(
    double value,
    AnimationStatus status,
  ) {
    return !_seenForwardAnimation &&
        !_seenReverseAnimation &&
        status == AnimationStatus.completed &&
        value >= 0.99 &&
        _transitionProgress <= 0.05;
  }

  void _syncSystemBackIntercepts() {
    final bool intercepts = _routeOpen && _systemBackHandle != null;
    QuranPlayerSystemBackCoordinator.setIntercepts(intercepts);
  }

  void _notifyAndLog(String event) {
    QuranPlayerDebugLog.animation(event, snapshot());
    _scheduleNotifyListeners();
  }

  /// Coalesced post-frame notification — avoids setState/markNeedsBuild during
  /// route build when `/player` pushes over the shell footer.
  void _scheduleNotifyListeners() {
    if (_notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @visibleForTesting
  void debugReset() {
    _phase = PlayerPresentationPhase.mini;
    _transitionProgress = 0;
    _routeOpen = false;
    _isDragging = false;
    _collapseBiased = false;
    _collapseRequested = false;
    _seenForwardAnimation = false;
    _seenReverseAnimation = false;
    _expandDragNetDy = 0;
    notifyListeners();
  }
}
