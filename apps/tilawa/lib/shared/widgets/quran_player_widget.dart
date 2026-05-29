import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/audio_player/domain/entities/player_background_configuration.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/get_history_by_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_history_section.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../../features/audio_player/presentation/player_presentation_controller.dart';
import '../../features/audio_player/presentation/player_presentation_phase.dart';
import '../../features/audio_player/presentation/quran_player_navigation.dart';
import '../../features/audio_player/presentation/quran_player_presentation_entry.dart';
import '../../features/audio_player/presentation/quran_player_semantics_ids.dart';
import '../../features/audio_player/presentation/widgets/background_source_dialog.dart';
import '../../features/audio_player/presentation/widgets/player_background_layer.dart';
import '../../features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../helpers/show_slider_dialog.dart';
import '../models/position_data.dart';
import 'quran_player_chrome.dart';
import 'quran_player_debug_log.dart';
import 'quran_player_expand_physics.dart';
import 'quran_player_hero.dart';
import 'quran_player_morph_layer.dart';
import 'quran_player_morph_layout.dart';
import 'quran_player_progress_display.dart';
import 'quran_player_queue_utils.dart';
import 'quran_player_system_back.dart';
import 'quran_player_transport_controls.dart';

/// A YouTube Music-style sliding player panel.
///
/// When collapsed, shows a compact mini player above the bottom nav.
/// Tap or swipe up to expand to a full-screen now-playing sheet with queue.
/// Swipe down on the sheet or tap the chevron to collapse.
class QuranPlayerWidget extends StatefulWidget {
  const QuranPlayerWidget({
    super.key,
    this.bottomNavBarHeight = 0,
    this.isKeyboardOpen = false,
    this.phoneBottomNavBarVisible,
    this.hostAbsorbsBottomSafeArea = false,
    this.embeddedInShellFooter = false,
  });

  static double collapsedHeight(BuildContext context) =>
      context.tokens.playerCollapsedHeight;

  /// Vertical space above the screen bottom occupied by the collapsed
  /// mini-player. Mirrors the player's own anchoring at
  /// `Positioned(bottom: bottomNavBarHeight + safeAreaPadding)`, so:
  ///
  ///   footprint = collapsedHeight + bottomNavBarHeight + safeAreaPadding
  ///   (omit safe area padding when [hostAbsorbsBottomSafeArea] is true).
  ///
  /// Use this to inset content (lists, FABs, scrollbars) so it isn't
  /// covered by the player.
  ///
  /// Insets scroll content so it is not covered by the global mini-player.
  ///
  /// On `/`, reads [QuranPlayerChromeNotifier] published by [MainScreen].
  /// On other routes (e.g. `/downloads`), uses [floatingBottomPadding] only.
  static double collapsedFootprint(
    BuildContext context, {
    double bottomNavBarHeight = 0,
    bool hostAbsorbsBottomSafeArea = false,
  }) {
    final String location = GoRouterState.of(context).uri.path;
    if (!QuranPlayerRoutePolicy.shouldShowPlayer(location)) {
      return 0;
    }

    if (QuranPlayerRoutePolicy.isInAppShell(location)) {
      final QuranPlayerShellChrome? shell = context
          .read<QuranPlayerChromeNotifier>()
          .shellChrome;
      if (shell != null) {
        if (context.isNarrow && shell.bottomNavBarHeight > 0) {
          return collapsedHeight(context);
        }
        return collapsedHeight(context) +
            shell.bottomNavBarHeight +
            (shell.hostAbsorbsBottomSafeArea
                ? 0
                : context.floatingBottomPadding);
      }
    }

    return collapsedHeight(context) +
        bottomNavBarHeight +
        (hostAbsorbsBottomSafeArea ? 0 : context.floatingBottomPadding);
  }

  /// Bottom inset for a [FloatingActionButton] on the current route.
  ///
  /// On phone shell layouts the mini-player sits in the shell footer column
  /// below this [Scaffold], so only a small margin is needed. When the player
  /// overlays the scaffold (e.g. wide layout), use [collapsedFootprint].
  static double fabBottomOffset(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (!QuranPlayerRoutePolicy.shouldShowPlayer(location)) {
      return context.tokens.spaceMedium;
    }

    if (QuranPlayerRoutePolicy.isInAppShell(location)) {
      final QuranPlayerShellChrome? shell = context
          .read<QuranPlayerChromeNotifier>()
          .shellChrome;
      if (shell != null && context.isNarrow && shell.bottomNavBarHeight > 0) {
        return context.tokens.spaceSmall;
      }
    }

    return collapsedFootprint(context);
  }

  /// Height of the bottom navigation bar to offset the mini player.
  final double bottomNavBarHeight;

  /// Whether the keyboard is currently open.
  final bool isKeyboardOpen;

  /// When non-null, set to `false` while expand progress is at or above
  /// [TilawaDesignTokens.playerProgressThreshold] so a host
  /// [TilawaAdaptiveShell] can hide its phone bottom bar for a true
  /// full-screen expanded player. Stays `true` while collapsed so dismiss
  /// gestures never hide the bar.
  final ValueNotifier<bool>? phoneBottomNavBarVisible;

  /// When true with [bottomNavBarHeight] == 0, the mini player anchors flush
  /// to the layout bottom (no [floatingBottomPadding]) because the host already
  /// stacks bottom chrome (e.g. phone-layout shell [BottomNavigationBar]) that
  /// includes the system gesture inset.
  final bool hostAbsorbsBottomSafeArea;

  /// When true, the mini player is laid out in [TilawaAdaptiveShell]'s
  /// [TilawaAdaptiveShell.phoneFooterAboveNav] slot (above the bottom nav).
  /// The expanded sheet is rendered in the root overlay via [OverlayPortal].
  final bool embeddedInShellFooter;

  @override
  State<QuranPlayerWidget> createState() => QuranPlayerWidgetState();
}

class QuranPlayerWidgetState extends State<QuranPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  final OverlayPortalController _portalController = OverlayPortalController();
  bool _portalVisibilitySyncScheduled = false;

  late PlayerPresentationController _presentation;
  String? _lastSyncedRoutePath;
  late final void Function() _systemBackHandle;
  late final void Function() _dismissHandle;
  late AudioPlayerBloc _audioBloc;

  /// Set by [collapse] until the sheet settles at progress 0.
  ///
  /// [AnimationController.status] stays [AnimationStatus.forward] during
  /// [AnimationController.animateTo] toward 0 on some runtimes, so we cannot
  /// rely on [AnimationStatus.reverse] to detect collapse.
  bool _isCollapsing = false;

  /// True while the user is driving [_expandController] with a drag gesture.
  bool _isUserDraggingExpand = false;

  /// Cumulative downward (+) / upward (-) drag during an expand gesture.
  double _expandDragNetDy = 0;

  /// Progress when the current expand/collapse drag began.
  double _expandDragStartProgress = 0;

  double? _lastLoggedExpandProgress;
  int _lastDragLogMs = 0;
  String? _lastLayoutLogSignature;

  /// Controls the swipe-down-to-dismiss offset for the mini player.
  double _dismissOffsetY = 0;
  Animation<double>? _dismissAnimation;
  late AnimationController _dismissAnimController;

  /// The height of the mini player bar (excluding nav bar offset).
  /// Must be tall enough for: outer padding (8+16) + progress bar (3) +
  /// inner padding (12+12) + row content (~48) = ~99.
  double get _miniPlayerHeight => QuranPlayerWidget.collapsedHeight(context);

  /// Whether the player is currently expanded.
  bool get isExpanded => _usesHeroExpansion
      ? _presentation.isExpandedSettled
      : _expandController.value == 1.0;

  /// Whether the player is currently expanding or expanded.
  bool get isExpanding => _usesHeroExpansion
      ? _presentation.routeOpen || _presentation.visualProgress > 0.01
      : _expandController.value > 0.01;

  double get _visualExpandProgress => _usesHeroExpansion
      ? _presentation.visualProgress
      : _expandController.value;

  /// Shell footer uses a root [Hero] route instead of [OverlayPortal] morphing.
  bool get _usesHeroExpansion => widget.embeddedInShellFooter;

  Map<String, Object?> _coreStateFields() {
    if (_usesHeroExpansion) {
      return <String, Object?>{
        ..._presentation.snapshot(),
        'dismissOffsetY': _dismissOffsetY.toStringAsFixed(1),
        'route': _currentRoutePath(),
        'embeddedInShellFooter': widget.embeddedInShellFooter,
        'portalShowing': null,
      };
    }
    return <String, Object?>{
      'visualMode': QuranPlayerDebugLog.playerMode(
        expandProgress: _expandController.value,
        isCollapsing: _isCollapsing,
        isUserDragging: _isUserDraggingExpand,
        transitionOwner: 'expandController',
      ),
      'visualProgress': _expandController.value.toStringAsFixed(3),
      'transitionOwner': 'expandController',
      'renderTree': 'overlay',
      'expandStatus': _expandController.status.name,
      'expandIsAnimating': _expandController.isAnimating,
      'isCollapsing': _isCollapsing,
      'isUserDragging': _isUserDraggingExpand,
      'dismissOffsetY': _dismissOffsetY.toStringAsFixed(1),
      'route': _currentRoutePath(),
      'embeddedInShellFooter': widget.embeddedInShellFooter,
      'portalShowing': widget.embeddedInShellFooter
          ? _portalController.isShowing
          : null,
    };
  }

  void _logAnimationControllers(String event) {
    QuranPlayerDebugLog.animation(
      event,
      <String, Object?>{
        ..._coreStateFields(),
        'dismissAnimValue': _dismissAnimController.value.toStringAsFixed(3),
        'dismissAnimStatus': _dismissAnimController.status.name,
      },
    );
  }

  void _maybeLogDragProgress(String source, {required double primaryDelta}) {
    if (!QuranPlayerDebugLog.enabled) {
      return;
    }
    final double progress = _visualExpandProgress;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final double? last = _lastLoggedExpandProgress;
    final bool progressMoved =
        last == null || (progress - last).abs() >= 0.025;
    final bool throttled = now - _lastDragLogMs < 100;
    if (!progressMoved && throttled) {
      return;
    }
    _lastLoggedExpandProgress = progress;
    _lastDragLogMs = now;
    final metrics = _transitionMetrics(progress);
    QuranPlayerDebugLog.maybeWarnTransitionGap(
      progress: progress,
      miniOpacity: metrics.miniOpacity,
      expandedOpacity: metrics.expandedOpacity,
      source: source,
    );
    QuranPlayerDebugLog.drag(
      'update',
      <String, Object?>{
        'source': source,
        'primaryDelta': primaryDelta.toStringAsFixed(1),
        ..._coreStateFields(),
        'miniOpacity': metrics.miniOpacity.toStringAsFixed(3),
        'expandedOpacity': metrics.expandedOpacity.toStringAsFixed(3),
        'sheetPresentationOpacity':
            metrics.sheetPresentationOpacity.toStringAsFixed(3),
        'sheetMotionT': metrics.sheetMotionT.toStringAsFixed(3),
        'queueChromeT': metrics.queueChromeT.toStringAsFixed(3),
        'showMini': metrics.showMiniPlayer,
        'showExpanded': metrics.showExpandedSheet,
      },
    );
  }

  void _maybeLogLayoutTree({
    required String tree,
    required double progress,
    required PlayerExpandTransitionMetrics metrics,
    required Size overlaySize,
    required Rect hostRect,
    required bool showMiniInTree,
    required bool miniAnchoredInFooter,
    required bool animateShellInOverlay,
    required double bottomInset,
  }) {
    if (!QuranPlayerDebugLog.enabled) {
      return;
    }
    final String signature =
        '$tree|${progress.toStringAsFixed(2)}|'
        '${metrics.showMiniPlayer}|${metrics.showExpandedSheet}|'
        '$animateShellInOverlay';
    if (_lastLayoutLogSignature == signature) {
      return;
    }
    _lastLayoutLogSignature = signature;
    QuranPlayerDebugLog.maybeWarnTransitionGap(
      progress: progress,
      miniOpacity: metrics.miniOpacity,
      expandedOpacity: metrics.expandedOpacity,
      source: 'layout.$tree',
    );
    QuranPlayerDebugLog.layout(
      'tree',
      <String, Object?>{
        'tree': tree,
        ..._coreStateFields(),
        'overlayW': overlaySize.width.toStringAsFixed(0),
        'overlayH': overlaySize.height.toStringAsFixed(0),
        'hostTop': hostRect.top.toStringAsFixed(0),
        'hostBottom': hostRect.bottom.toStringAsFixed(0),
        'showMiniInTree': showMiniInTree,
        'miniAnchoredInFooter': miniAnchoredInFooter,
        'animateShellInOverlay': animateShellInOverlay,
        'bottomInset': bottomInset.toStringAsFixed(1),
        'miniOpacity': metrics.miniOpacity.toStringAsFixed(3),
        'expandedOpacity': metrics.expandedOpacity.toStringAsFixed(3),
        'sheetPresentationOpacity':
            metrics.sheetPresentationOpacity.toStringAsFixed(3),
        'scrimOpacity': metrics.scrimOpacity.toStringAsFixed(3),
        'sheetMotionT': metrics.sheetMotionT.toStringAsFixed(3),
        'queueChromeT': metrics.queueChromeT.toStringAsFixed(3),
        'showMini': metrics.showMiniPlayer,
        'showExpanded': metrics.showExpandedSheet,
        if (miniAnchoredInFooter && _usesHeroExpansion)
          'expandedInFooterTree': false,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    QuranPlayerDebugLog.lifecycle('initState', <String, Object?>{
      'embeddedInShellFooter': widget.embeddedInShellFooter,
    });
    // Token-aligned: durationMedium (400ms). Cannot read tokens in initState
    // (no theme/build context yet); keep literals in sync with
    // TilawaDesignTokens by hand.
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Token-aligned: durationFast (200ms). See note above.
    _dismissAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _presentation = getIt<PlayerPresentationController>();
    _expandController.addListener(_syncPhoneBottomNavBarVisible);
    _expandController.addListener(_syncExpandedPlayerSystemChrome);
    _expandController.addListener(_syncSystemBackIntercepts);
    _expandController.addStatusListener(_onExpandAnimationStatus);
    _presentation.addListener(_onPresentationChanged);

    _systemBackHandle = handleSystemBack;
    _dismissHandle = _dismissWithUndo;
    _presentation.bindSystemBack(handle: _systemBackHandle);
    _presentation.bindDismissPlayer(handle: _dismissHandle);
    _logAnimationControllers('initState.controllersReady');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        QuranPlayerDebugLog.lifecycle('firstFrame', _coreStateFields());
        _syncPhoneBottomNavBarVisible();
        _syncExpandedPlayerSystemChrome();
        if (widget.embeddedInShellFooter && !_usesHeroExpansion) {
          _schedulePortalVisibilitySync();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioBloc = context.read<AudioPlayerBloc>();
    QuranPlayerSystemBackCoordinator.bind(handle: _systemBackHandle);
    _syncSystemBackIntercepts();
    final String path = _currentRoutePath();
    if (_lastSyncedRoutePath != path) {
      QuranPlayerDebugLog.route(
        'changed',
        <String, Object?>{
          'from': _lastSyncedRoutePath,
          'to': path,
          ..._coreStateFields(),
        },
      );
      _lastSyncedRoutePath = path;
      _syncPhoneBottomNavBarVisible();
      if (_usesHeroExpansion) {
        _reconcileHeroRouteWithNavigation();
      } else {
        _settleExpandOnRouteChange();
      }
    }
  }

  @override
  void didUpdateWidget(covariant QuranPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneBottomNavBarVisible != widget.phoneBottomNavBarVisible ||
        oldWidget.embeddedInShellFooter != widget.embeddedInShellFooter ||
        oldWidget.bottomNavBarHeight != widget.bottomNavBarHeight ||
        oldWidget.isKeyboardOpen != widget.isKeyboardOpen) {
      QuranPlayerDebugLog.lifecycle(
        'didUpdateWidget',
        <String, Object?>{
          ..._coreStateFields(),
          'navNotifierChanged':
              oldWidget.phoneBottomNavBarVisible !=
              widget.phoneBottomNavBarVisible,
          'keyboardOpen': widget.isKeyboardOpen,
          'bottomNavBarHeight': widget.bottomNavBarHeight,
        },
      );
    }
    if (oldWidget.phoneBottomNavBarVisible != widget.phoneBottomNavBarVisible) {
      _syncPhoneBottomNavBarVisible();
    }
  }

  @override
  void deactivate() {
    QuranPlayerDebugLog.lifecycle('deactivate', _coreStateFields());
    QuranPlayerSystemBackCoordinator.setIntercepts(false);
    QuranPlayerSystemBackCoordinator.unbind(handle: _systemBackHandle);
    context
        .read<QuranPlayerChromeNotifier>()
        .clearSystemNavigationBarColorOverride();
    super.deactivate();
  }

  @override
  void dispose() {
    QuranPlayerDebugLog.lifecycle('dispose', _coreStateFields());
    _presentation.unbindDismissPlayer(handle: _dismissHandle);
    _presentation.unbindSystemBack(handle: _systemBackHandle);
    _presentation.removeListener(_onPresentationChanged);
    QuranPlayerSystemBackCoordinator.unbind(handle: _systemBackHandle);
    _expandController.removeStatusListener(_onExpandAnimationStatus);
    _expandController.removeListener(_syncPhoneBottomNavBarVisible);
    _expandController.removeListener(_syncExpandedPlayerSystemChrome);
    _expandController.removeListener(_syncSystemBackIntercepts);
    _expandController.dispose();
    _dismissAnimController.dispose();
    super.dispose();
  }

  void _syncSystemBackIntercepts() {
    if (!mounted) {
      QuranPlayerSystemBackCoordinator.setIntercepts(false);
      return;
    }
    final bool intercepts =
        QuranPlayerRoutePolicy.shouldShowPlayer(_currentRoutePath()) &&
        _audioBloc.state.shouldShowBottomPlayer &&
        (_usesHeroExpansion ? _presentation.routeOpen : isExpanding);
    QuranPlayerSystemBackCoordinator.setIntercepts(intercepts);
  }

  /// Collapse the expanded now-playing sheet on system back.
  ///
  /// The mini player is not stopped here; dismissal stays on swipe-down or the
  /// overflow menu stop action.
  void handleSystemBack() {
    if (!mounted || !isExpanding) {
      return;
    }
    collapse();
  }

  void _onPresentationChanged() {
    if (!mounted) {
      return;
    }
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_usesHeroExpansion &&
          _presentation.phase == PlayerPresentationPhase.mini) {
        _isCollapsing = false;
      }
      _syncPhoneBottomNavBarVisible();
      _syncExpandedPlayerSystemChrome();
      _syncSystemBackIntercepts();
    });
  }

  /// Edge-to-edge nav is transparent; publish the queue sheet color app-wide
  /// so [TilawaApp] does not reset the gesture strip to white each frame.
  void _syncExpandedPlayerSystemChrome() {
    if (!mounted) {
      return;
    }
    final QuranPlayerChromeNotifier notifier = context
        .read<QuranPlayerChromeNotifier>();
    final bool overlayActive = _usesHeroExpansion
        ? _presentation.overlayChromeActive
        : _expandController.value > 0.01 &&
            (!widget.embeddedInShellFooter || _portalController.isShowing);
    if (overlayActive) {
      notifier.setSystemNavigationBarColorOverride(
        quranPlayerQueueSheetColor(Theme.of(context).colorScheme),
      );
    } else {
      notifier.clearSystemNavigationBarColorOverride();
    }
  }

  void _schedulePortalVisibilitySync() {
    if (_portalVisibilitySyncScheduled) {
      return;
    }
    _portalVisibilitySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portalVisibilitySyncScheduled = false;
      if (!mounted) {
        QuranPlayerDebugLog.warn(
          'overlay.portalSync.unmounted',
          const <String, Object?>{},
        );
        return;
      }
      final bool wasShowing = _portalController.isShowing;
      if (!wasShowing) {
        _portalController.show();
      }
      QuranPlayerDebugLog.overlay(
        'portalSync',
        <String, Object?>{
          'wasShowing': wasShowing,
          'isShowing': _portalController.isShowing,
          ..._coreStateFields(),
        },
      );
      _syncExpandedPlayerSystemChrome();
    });
  }

  /// Expand the player to full-screen.
  ///
  /// Shell footer: pushes a [Hero] route. Other layouts: animates progress.
  void expand() {
    HapticFeedback.lightImpact();
    _isCollapsing = false;
    _lastLayoutLogSignature = null;
    if (_usesHeroExpansion) {
      QuranPlayerPresentationEntry.openExpanded(
        presentation: _presentation,
        hasActiveAudio: _audioBloc.state.hasAudio,
      );
      return;
    }
    QuranPlayerDebugLog.animation(
      'expand.start',
      <String, Object?>{
        'from': _expandController.value.toStringAsFixed(3),
        'hero': false,
        ..._coreStateFields(),
      },
    );
    _expandController.animateTo(
      1.0,
      duration: context.tokens.durationMedium,
      curve: Curves.easeOutCubic,
    );
  }

  /// Collapse the player back to the mini bar.
  void collapse() {
    _isCollapsing = true;
    _lastLayoutLogSignature = null;
    QuranPlayerDebugLog.animation(
      'collapse.start',
      <String, Object?>{
        'from': _expandController.value.toStringAsFixed(3),
        'hero': _usesHeroExpansion,
        ..._coreStateFields(),
      },
    );
    if (_usesHeroExpansion) {
      _presentation.collapse();
      return;
    }
    _expandController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  /// Phone shell: animate sheet + mini in one overlay layer to avoid desync.
  bool get _animateShellInOverlay =>
      widget.embeddedInShellFooter && _expandController.isAnimating;

  void _onExpandAnimationStatus(AnimationStatus status) {
    if (!mounted) {
      return;
    }
    QuranPlayerDebugLog.animation(
      'expand.status',
      <String, Object?>{
        'status': status.name,
        'value': _expandController.value.toStringAsFixed(3),
        'isAnimating': _expandController.isAnimating,
        'isCollapsing': _isCollapsing,
        ..._coreStateFields(),
      },
    );
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (!_usesHeroExpansion) {
        if (_expandController.value <= 0.01) {
          _isCollapsing = false;
        }
        if (_expandController.value >= 0.99) {
          _isCollapsing = false;
        }
      }
      _isUserDraggingExpand = false;
      _syncPhoneBottomNavBarVisible();
    }
  }

  void _syncPhoneBottomNavBarVisible() {
    final ValueNotifier<bool>? n = widget.phoneBottomNavBarVisible;
    if (n == null || !mounted) return;
    final String location = _currentRoutePath();
    final bool hideNavWhenExpanded =
        AppShellRoutePolicy.shouldHideBottomNavWhenPlayerExpanded(location);
    if (!hideNavWhenExpanded) {
      if (!n.value) {
        n.value = true;
      }
      return;
    }

    // Hold nav hidden for the whole programmatic collapse. animateTo(0) may
    // report AnimationStatus.forward, not reverse, on some runtimes.
    if (_isCollapsing && _expandController.isAnimating) {
      if (n.value) {
        n.value = false;
      }
      return;
    }

    final double threshold = context.tokens.playerProgressThreshold;
    final bool showBar = _visualExpandProgress < threshold;
    if (n.value != showBar) {
      QuranPlayerDebugLog.layout(
        'phoneBottomNav',
        <String, Object?>{
          'showBar': showBar,
          'progress': _visualExpandProgress.toStringAsFixed(3),
          'route': location,
        },
      );
      n.value = showBar;
    }
  }

  bool _collapseBiasedMetrics(double progress) {
    if (_isCollapsing) {
      return true;
    }
    if (_isUserDraggingExpand &&
        progress < _expandDragStartProgress - 0.001) {
      return true;
    }
    return false;
  }

  PlayerExpandTransitionMetrics _transitionMetrics(
    double progress, {
    bool footerHandoff = false,
  }) {
    return PlayerExpandTransitionMetrics.compute(
      progress: progress,
      miniPlayerHeight: _miniPlayerHeight,
      collapseBiased: _usesHeroExpansion
          ? _isCollapsing
          : _collapseBiasedMetrics(progress),
      heroHandoff: footerHandoff && _usesHeroExpansion,
    );
  }

  Rect _miniBarRectInOverlay({
    required Size overlaySize,
    required Rect hostRect,
    required bool showMiniInTree,
    required bool animateShellInOverlay,
    required double layoutBottomInset,
    required double miniSlideY,
  }) {
    if (!showMiniInTree || animateShellInOverlay) {
      return hostRect;
    }
    final double bottom = layoutBottomInset - miniSlideY;
    return Rect.fromLTWH(
      0,
      overlaySize.height - bottom - _miniPlayerHeight,
      overlaySize.width,
      _miniPlayerHeight,
    );
  }

  double _sheetTravelOffset({
    required PlayerExpandTransitionMetrics metrics,
    required double screenHeight,
    required double collapseAnchorY,
  }) {
    final double travel = collapseAnchorY > 0 ? collapseAnchorY : screenHeight;
    return travel * (1 - metrics.sheetMotionT);
  }

  Widget? _buildMorphLayer(
    BuildContext context, {
    required AudioEntity audio,
    required double progress,
    required PlayerExpandTransitionMetrics metrics,
    required Size overlaySize,
    required Rect miniBarRect,
    required double collapseAnchorY,
  }) {
    if (_usesHeroExpansion || !metrics.showMorphLayer) {
      return null;
    }
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final barTokens = theme.componentTokens.mediaPlayerBar;
    final geometry = QuranPlayerMorphThemeGeometry.fromBarTokens(
      spaceLarge: tokens.spaceLarge,
      progressHeight: tokens.progressHeight,
      barContentPadding: barTokens.contentPadding,
      barTokens: barTokens,
      expandedArtBorderRadius: tokens.radiusLarge,
    );
    final layout = QuranPlayerMorphLayout.compute(
      progress: progress,
      viewport: overlaySize,
      miniBarRect: miniBarRect,
      sheetOffsetY: _sheetTravelOffset(
        metrics: metrics,
        screenHeight: overlaySize.height,
        collapseAnchorY: collapseAnchorY,
      ),
      geometry: geometry,
    );
    return QuranPlayerMorphLayer(
      audio: audio,
      handoffT: metrics.handoffT,
      layout: layout,
      onImageBackdrop: false,
    );
  }

  /// Snaps hero presentation to GoRouter, or mid-transition overlay progress.
  void _settleExpandOnRouteChange() {
    if (_usesHeroExpansion) {
      return;
    }
    if (_isUserDraggingExpand) {
      _finishExpandDrag(
        DragEndDetails(),
        source: 'route',
      );
      return;
    }
    if (_expandController.isAnimating) {
      return;
    }
    final double progress = _expandController.value;
    if (progress <= 0.01 || progress >= 0.99) {
      return;
    }
    final double threshold = context.tokens.playerProgressThreshold;
    if (progress < threshold) {
      _expandController.value = 0;
      _isCollapsing = false;
    } else {
      expand();
    }
  }

  /// Keeps `/player` open over shell tab changes; resyncs after hot reload.
  void _reconcileHeroRouteWithNavigation() {
    final QuranPlayerNavigation navigation = getIt<QuranPlayerNavigation>();
    final bool playerOnStack = navigation.isExpandedRouteOnStack;

    // #region agent log
    QuranPlayerDebugLog.agent(
      hypothesisId: 'HR',
      location: 'quran_player_widget.dart:_reconcileHeroRouteWithNavigation',
      message: 'hero route reconcile',
      data: <String, Object?>{
        'playerOnStack': playerOnStack,
        'routeOpen': _presentation.routeOpen,
        'phase': _presentation.phase.name,
        'visualProgress': _presentation.visualProgress.toStringAsFixed(3),
        'shouldRestore': _presentation.shouldRestoreExpandedRoute,
        'matchedPath': _currentRoutePath(),
      },
    );
    // #endregion

    if (playerOnStack) {
      return;
    }

    if (!_presentation.routeOpen && _presentation.visualProgress <= 0.01) {
      return;
    }

    if (kDebugMode &&
        _presentation.shouldRestoreExpandedRoute &&
        _audioBloc.state.hasAudio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (getIt<QuranPlayerNavigation>().isExpandedRouteOnStack) {
          return;
        }
        QuranPlayerDebugLog.animation(
          'reconcile.restoreExpanded',
          _coreStateFields(),
        );
        QuranPlayerPresentationEntry.openExpanded(
          presentation: _presentation,
          hasActiveAudio: _audioBloc.state.hasAudio,
        );
      });
      return;
    }

    _presentation.reconcileWithNavigationStack();
    _isCollapsing = false;
  }

  void _onExpandGestureStart() {
    _isUserDraggingExpand = true;
    _expandDragStartProgress = _expandController.value;
    _expandDragNetDy = 0;
    _expandController.stop();
    _isCollapsing = false;
    _lastLoggedExpandProgress = null;
    _lastLayoutLogSignature = null;
    QuranPlayerDebugLog.drag(
      'expandGesture.start',
      <String, Object?>{
        ..._coreStateFields(),
        'expandWasAnimating': _expandController.isAnimating,
      },
    );
  }

  void _applyExpandDragPixels(double dragPixels, {required String source}) {
    if (!mounted) {
      QuranPlayerDebugLog.warn(
        'drag.update.unmounted',
        <String, Object?>{'source': source},
      );
      return;
    }
    if (_usesHeroExpansion) {
      return;
    }
    final tokens = context.tokens;
    final double travel = QuranPlayerExpandPhysics.travelPixels(
      context.viewportHeight,
      tokens.playerDragSensitivity,
    );
    _expandDragNetDy += dragPixels;
    final double before = _expandController.value;
    final double next = QuranPlayerExpandPhysics.applyDragDelta(
      current: before,
      dragPixels: dragPixels,
      travelPixels: travel,
    );
    if ((next - before).abs() > 0.0001) {
      _expandController.value = next;
    }
    _maybeLogDragProgress(source, primaryDelta: dragPixels);
  }

  void _finishExpandDrag(DragEndDetails details, {required String source}) {
    _isUserDraggingExpand = false;
    final tokens = context.tokens;
    final double primaryVelocity = details.primaryVelocity ?? 0;
    final double progress = _expandController.value;
    final double netDragDy = _expandDragNetDy;
    final PlayerExpandSnapTarget target = QuranPlayerExpandPhysics.resolveSnap(
      progress: progress,
      primaryVelocity: primaryVelocity,
      progressThreshold: tokens.playerProgressThreshold,
      velocityThreshold: tokens.playerVelocityThreshold,
      netDragDy: netDragDy,
    );
    _expandDragNetDy = 0;
    QuranPlayerDebugLog.drag(
      'expandGesture.end',
      <String, Object?>{
        'source': source,
        'snap': target.name,
        'primaryVelocity': primaryVelocity.toStringAsFixed(1),
        'netDragDy': netDragDy.toStringAsFixed(1),
        'progressThreshold': tokens.playerProgressThreshold,
        'velocityThreshold': tokens.playerVelocityThreshold,
        ..._coreStateFields(),
      },
    );
    if (target == PlayerExpandSnapTarget.expand) {
      if (progress < 0.92) {
        expand();
      }
    } else {
      if (progress > 0.08) {
        collapse();
      } else {
        _expandController.value = 0;
        _isCollapsing = false;
      }
    }
  }

  /// Bottom inset for the floating mini player while [progress] is animating.
  double _miniPlayerBottomInsetForProgress(
    BuildContext context,
    double progress,
  ) {
    final String location = _currentRoutePath();
    final bool hideNavWhenExpanded =
        AppShellRoutePolicy.shouldHideBottomNavWhenPlayerExpanded(location);
    final double threshold = context.tokens.playerProgressThreshold;
    final bool phoneNavVisible = !hideNavWhenExpanded || progress < threshold;
    return QuranPlayerLayoutInsets.miniPlayerBottomInset(
      context: context,
      hostBottomNavBarHeight: widget.bottomNavBarHeight,
      hostAbsorbsBottomSafeArea: widget.hostAbsorbsBottomSafeArea,
      phoneNavVisible: phoneNavVisible,
      routePath: location,
    );
  }

  void _ensurePhoneBottomNavBarShown() {
    final ValueNotifier<bool>? n = widget.phoneBottomNavBarVisible;
    if (n == null || n.value) return;
    n.value = true;
  }

  /// Current route path without [GoRouterState.of] (overlay is above the router).
  static String _currentRoutePath() =>
      QuranPlayerRoutePolicy.currentMatchedLocation();

  /// Bottom offset for the mini player above nav chrome and the home indicator.
  double _resolveBottomInset(BuildContext context) {
    final bool navVisible = widget.phoneBottomNavBarVisible?.value ?? true;
    return QuranPlayerLayoutInsets.miniPlayerBottomInset(
      context: context,
      hostBottomNavBarHeight: widget.bottomNavBarHeight,
      hostAbsorbsBottomSafeArea: widget.hostAbsorbsBottomSafeArea,
      phoneNavVisible: navVisible,
      routePath: _currentRoutePath(),
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_expandController.value > 0.01) {
      _onExpandGestureStart();
    }
    QuranPlayerDebugLog.drag(
      'mini.start',
      <String, Object?>{
        'globalDy': details.globalPosition.dy.toStringAsFixed(1),
        'localDy': details.localPosition.dy.toStringAsFixed(1),
        ..._coreStateFields(),
      },
    );
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final double primaryDelta = details.primaryDelta ?? 0;
    if ((_expandController.value == 0 && primaryDelta > 0) ||
        _dismissOffsetY > 0) {
      setState(() {
        _dismissOffsetY = (_dismissOffsetY + primaryDelta).clamp(
          0.0,
          context.tokens.playerMaxDismissOffset,
        );
      });
      _maybeLogDragProgress(
        'mini.dismiss',
        primaryDelta: primaryDelta,
      );
      return;
    }

    if (_usesHeroExpansion && !_presentation.routeOpen) {
      _expandDragNetDy += primaryDelta;
      return;
    }

    if (_expandController.value <= 0 && primaryDelta < 0) {
      _onExpandGestureStart();
    }
    _applyExpandDragPixels(primaryDelta, source: 'mini');
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final tokens = context.tokens;
    final double primaryVelocity = details.primaryVelocity ?? 0;
    if (_dismissOffsetY > 0) {
      final String decision =
          primaryVelocity > tokens.playerDismissVelocityThreshold ||
              _dismissOffsetY > tokens.playerDismissThreshold
          ? 'dismiss'
          : 'dismissReset';
      QuranPlayerDebugLog.drag(
        'mini.end.dismiss',
        <String, Object?>{
          'decision': decision,
          'dismissOffsetY': _dismissOffsetY.toStringAsFixed(1),
          'dismissThreshold': tokens.playerDismissThreshold,
          'dismissVelocityThreshold': tokens.playerDismissVelocityThreshold,
          'primaryVelocity': primaryVelocity.toStringAsFixed(1),
          ..._coreStateFields(),
        },
      );
      if (primaryVelocity > tokens.playerDismissVelocityThreshold ||
          _dismissOffsetY > tokens.playerDismissThreshold) {
        _dismissWithUndo();
      } else {
        _animateDismissReset();
      }
      return;
    }

    if (_usesHeroExpansion && !_presentation.routeOpen) {
      final double netDragDy = _expandDragNetDy;
      _expandDragNetDy = 0;
      final bool expandIntent =
          primaryVelocity < -tokens.playerVelocityThreshold ||
          netDragDy < -28;
      QuranPlayerDebugLog.drag(
        expandIntent ? 'mini.end.expand' : 'mini.end.noExpandHandler',
        <String, Object?>{
          'primaryVelocity': primaryVelocity.toStringAsFixed(1),
          'netDragDy': netDragDy.toStringAsFixed(1),
          ..._coreStateFields(),
        },
      );
      if (expandIntent) {
        expand();
      }
      return;
    }

    if (_expandController.value > 0.01 || _isUserDraggingExpand) {
      _finishExpandDrag(details, source: 'mini');
    } else {
      QuranPlayerDebugLog.drag(
        'mini.end.noExpandHandler',
        <String, Object?>{
          'primaryVelocity': primaryVelocity.toStringAsFixed(1),
          ..._coreStateFields(),
        },
      );
    }
  }

  /// Cancel the dismiss gesture and spring back.
  void _animateDismissReset() {
    QuranPlayerDebugLog.drag(
      'mini.dismissReset',
      <String, Object?>{
        'fromOffsetY': _dismissOffsetY.toStringAsFixed(1),
        ..._coreStateFields(),
      },
    );
    _dismissAnimation = Tween<double>(begin: _dismissOffsetY, end: 0).animate(
      CurvedAnimation(parent: _dismissAnimController, curve: Curves.easeOut),
    );
    _dismissAnimController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _dismissOffsetY = 0;
      });
    });
  }

  void _dismissWithUndo() {
    QuranPlayerDebugLog.drag('mini.dismiss.commit', _coreStateFields());
    HapticFeedback.lightImpact();
    if (_usesHeroExpansion && _presentation.routeOpen) {
      _presentation.collapse();
    }
    context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.stopAudio());
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranPlayerWidget');

    if (widget.embeddedInShellFooter) {
      if (_usesHeroExpansion) {
        return _buildShellFooterMini(context);
      }
      _schedulePortalVisibilitySync();
      return OverlayPortal.overlayChildLayoutBuilder(
        controller: _portalController,
        overlayChildBuilder: _buildExpandedOverlay,
        child: _buildShellFooterMini(context),
      );
    }

    final Size size = MediaQuery.sizeOf(context);
    if (size.isEmpty) {
      return const SizedBox.shrink();
    }

    final double bottomInset = _resolveBottomInset(context);
    final double miniHeight = _miniPlayerHeight;
    final Rect hostRect = Rect.fromLTWH(
      0,
      size.height - bottomInset - miniHeight,
      size.width,
      miniHeight,
    );

    return _buildPlayerTree(
      context,
      hostRect: hostRect,
      overlaySize: size,
      showMiniInTree: true,
    );
  }

  /// Mini player anchored in the shell footer column (YouTube Music style).
  Widget _buildShellFooterMini(BuildContext context) {
    return SizedBox(
      height: _miniPlayerHeight,
      width: double.infinity,
      child: _buildPlayerTree(
        context,
        hostRect:
            Offset.zero &
            Size(MediaQuery.sizeOf(context).width, _miniPlayerHeight),
        overlaySize: MediaQuery.sizeOf(context),
        showMiniInTree: true,
        miniAnchoredInFooter: true,
      ),
    );
  }

  Widget _buildExpandedOverlay(
    BuildContext overlayContext,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    if (layoutInfo.childPaintTransform.determinant() == 0.0) {
      QuranPlayerDebugLog.warn(
        'overlay.degenerateTransform',
        <String, Object?>{
          'childSize': layoutInfo.childSize,
          'overlaySize': layoutInfo.overlaySize,
        },
      );
      return const SizedBox.shrink();
    }

    final Rect hostRect = MatrixUtils.transformRect(
      layoutInfo.childPaintTransform,
      Offset.zero & layoutInfo.childSize,
    );
    QuranPlayerDebugLog.overlay(
      'build',
      <String, Object?>{
        'hostTop': hostRect.top.toStringAsFixed(0),
        'hostBottom': hostRect.bottom.toStringAsFixed(0),
        'overlayW': layoutInfo.overlaySize.width.toStringAsFixed(0),
        'overlayH': layoutInfo.overlaySize.height.toStringAsFixed(0),
        ..._coreStateFields(),
      },
    );

    return _buildPlayerTree(
      overlayContext,
      hostRect: hostRect,
      overlaySize: layoutInfo.overlaySize,
      showMiniInTree: false,
    );
  }

  Widget _buildPlayerTree(
    BuildContext context, {
    required Rect hostRect,
    required Size overlaySize,
    required bool showMiniInTree,
    bool miniAnchoredInFooter = false,
  }) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (previous, current) {
        return previous.currentAudio?.id != current.currentAudio?.id ||
            (!previous.shouldShowBottomPlayer &&
                current.shouldShowBottomPlayer) ||
            (previous.isPlaying != current.isPlaying && current.isPlaying) ||
            previous.failure != current.failure;
      },
      buildWhen: QuranPlayerTransportControls.playerTreeBuildWhen,
      listener: (context, state) {
        _syncSystemBackIntercepts();
        // Reset dismiss animation so the mini player is not offset off-screen
        // from a previous dismiss gesture.
        if (_dismissAnimation != null ||
            _dismissAnimController.value != 0 ||
            _dismissOffsetY != 0) {
          _dismissAnimation = null;
          _dismissAnimController.value = 0;
          _dismissOffsetY = 0;
        }
        final String? message = state.failure?.localizedMessage(context);
        if (message != null) {
          ToastUtils.showErrorToast(message);
        }
      },
      builder: (context, state) {
        _syncSystemBackIntercepts();
        final audio = state.currentAudio;
        final bool isCurrentAudioDismissed =
            audio != null && state.dismissedAudioId == audio.id;
        final bool hideForKeyboard = widget.isKeyboardOpen && !isExpanding;
        final bool shouldHideTree =
            audio == null || isCurrentAudioDismissed || hideForKeyboard;

        if (shouldHideTree) {
          QuranPlayerDebugLog.layout(
            'tree.hidden',
            <String, Object?>{
              'audioNull': audio == null,
              'dismissed': isCurrentAudioDismissed,
              'hideForKeyboard': hideForKeyboard,
              ..._coreStateFields(),
            },
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ensurePhoneBottomNavBarShown();
          });
          return const SizedBox.shrink();
        }

        final double screenHeight = overlaySize.height;

        final Widget expandedPlayer = RepaintBoundary(
          child: _ExpandedPlayerOrganism(
            state: state,
            audio: audio,
            expandAnimation: _expandController,
            onCollapse: collapse,
            onDismiss: _dismissWithUndo,
            onPlayerExpandDragStart: _onExpandGestureStart,
            onPlayerExpandDragUpdate: (double dy) =>
                _applyExpandDragPixels(dy, source: 'expanded'),
            onPlayerExpandDragEnd: (DragEndDetails details) =>
                _finishExpandDrag(details, source: 'expanded'),
          ),
        );

        return AnimatedBuilder(
          animation:             Listenable.merge(
            <Listenable>[
              _expandController,
              if (_usesHeroExpansion) _presentation,
            ],
          ),
          child: expandedPlayer,
          builder: (context, expandedChild) {
            final double progress = _usesHeroExpansion
                ? _visualExpandProgress
                : _expandController.value;
            final PlayerExpandTransitionMetrics metrics = _usesHeroExpansion &&
                    miniAnchoredInFooter
                ? _presentation.metricsForFooter(
                    miniPlayerHeight: _miniPlayerHeight,
                  )
                : _transitionMetrics(progress);
            final bool animateShellInOverlay = _animateShellInOverlay;
            final double layoutBottomInset = showMiniInTree
                ? _miniPlayerBottomInsetForProgress(context, progress)
                : 0;

            _maybeLogLayoutTree(
              tree: !showMiniInTree
                  ? 'overlay'
                  : miniAnchoredInFooter
                  ? (_usesHeroExpansion && _presentation.routeOpen
                        ? 'footerMiniHeroHandoff'
                        : 'footerMini')
                  : 'stackMini',
              progress: progress,
              metrics: metrics,
              overlaySize: overlaySize,
              hostRect: hostRect,
              showMiniInTree: showMiniInTree,
              miniAnchoredInFooter: miniAnchoredInFooter,
              animateShellInOverlay: animateShellInOverlay,
              bottomInset: layoutBottomInset,
            );

            final Rect miniBarRect = _miniBarRectInOverlay(
              overlaySize: overlaySize,
              hostRect: hostRect,
              showMiniInTree: showMiniInTree,
              animateShellInOverlay: animateShellInOverlay,
              layoutBottomInset: layoutBottomInset,
              miniSlideY: metrics.miniSlideY,
            );
            final Widget? morphLayer = _buildMorphLayer(
              context,
              audio: audio,
              progress: progress,
              metrics: metrics,
              overlaySize: overlaySize,
              miniBarRect: miniBarRect,
              collapseAnchorY: hostRect.top,
            );

            // #region agent log
            if (_usesHeroExpansion && miniAnchoredInFooter) {
              QuranPlayerDebugLog.agent(
                hypothesisId: 'A',
                location: 'quran_player_widget.dart:footerBuilder',
                message: 'hero+morph stack state',
                throttleProgress: true,
                progress: progress,
                data: <String, Object?>{
                  'progress': progress.toStringAsFixed(3),
                  'morphVisible': morphLayer != null,
                  'handoffT': metrics.handoffT.toStringAsFixed(3),
                  'miniIdentityOpacity':
                      metrics.miniIdentityOpacity.toStringAsFixed(3),
                  'stageChromeOpacity':
                      metrics.stageChromeOpacity.toStringAsFixed(3),
                  'routeOpen': _presentation.routeOpen,
                  'phase': _presentation.phase.name,
                },
              );
            }
            // #endregion

            final Widget miniPlayer = Opacity(
              opacity: metrics.miniOpacity,
              child: Transform.translate(
                offset: Offset(0, metrics.miniSlideY),
                child: _MiniPlayerTransition(
                  progress: progress,
                  audio: audio,
                  useHeroArtwork: _usesHeroExpansion,
                  identityChromeOpacity: metrics.miniIdentityOpacity,
                  dismissAnimController: _dismissAnimController,
                  dismissAnimation: _dismissAnimation,
                  dismissOffsetY: _dismissOffsetY,
                  onVerticalDragStart: _onVerticalDragStart,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  onTap: expand,
                  onClose: _dismissWithUndo,
                ),
              ),
            );

            if (!showMiniInTree) {
              return SizedBox(
                height: screenHeight,
                width: overlaySize.width,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (progress > 0.001)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Theme.of(context).colorScheme.surface
                                .withValues(
                              alpha: metrics.backdropOpacity,
                            ),
                          ),
                        ),
                      ),
                    if (metrics.scrimOpacity > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Theme.of(context).colorScheme.scrim
                                .withValues(alpha: metrics.scrimOpacity),
                          ),
                        ),
                      ),
                    if (metrics.showExpandedSheet && expandedChild != null)
                      PlayerExpandMetricsScope(
                        metrics: metrics,
                        child: _ExpandedPlayerMotion(
                          sheetMotionT: metrics.sheetMotionT,
                          screenHeight: screenHeight,
                          sheetOpacity: metrics.sheetPresentationOpacity,
                          collapseAnchorY: hostRect.top,
                          semanticLabel: context
                              .l10n
                              .playerExpandedSheetSemanticLabel,
                          child: expandedChild,
                        ),
                      ),
                    if (animateShellInOverlay && metrics.showMiniPlayer)
                      Positioned(
                        top: hostRect.top,
                        left: 0,
                        right: 0,
                        height: _miniPlayerHeight,
                        child: miniPlayer,
                      ),
                    if (morphLayer != null)
                      Positioned.fill(child: morphLayer),
                  ],
                ),
              );
            }

            if (miniAnchoredInFooter) {
              return SizedBox(
                height: _miniPlayerHeight,
                child: animateShellInOverlay
                    ? const SizedBox.shrink()
                    : IgnorePointer(
                        ignoring: !metrics.showMiniPlayer,
                        child: metrics.showMiniPlayer
                            ? miniPlayer
                            : const SizedBox.shrink(),
                      ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                SizedBox(
                  height: screenHeight,
                  width: overlaySize.width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (progress > 0.001)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.surface
                                  .withValues(
                                alpha: metrics.backdropOpacity,
                              ),
                            ),
                          ),
                        ),
                      if (metrics.scrimOpacity > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Theme.of(context).colorScheme.scrim
                                  .withValues(alpha: metrics.scrimOpacity),
                            ),
                          ),
                        ),
                      if (metrics.showExpandedSheet && expandedChild != null)
                        PlayerExpandMetricsScope(
                          metrics: metrics,
                          child: _ExpandedPlayerMotion(
                            sheetMotionT: metrics.sheetMotionT,
                            screenHeight: screenHeight,
                            sheetOpacity: metrics.sheetPresentationOpacity,
                            collapseAnchorY: hostRect.top,
                            semanticLabel: context
                                .l10n
                                .playerExpandedSheetSemanticLabel,
                            child: expandedChild,
                          ),
                        ),
                      if (morphLayer != null)
                        Positioned.fill(child: morphLayer),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: layoutBottomInset - metrics.miniSlideY,
                  height: _miniPlayerHeight,
                  child: IgnorePointer(
                    ignoring: !metrics.showMiniPlayer,
                    child: metrics.showMiniPlayer
                        ? miniPlayer
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Organisms
// ---------------------------------------------------------------------------

/// Slide/scale motion for the expanded sheet during expand/collapse.
///
/// Kept separate from [_ExpandedPlayerOrganism] so only this lightweight
/// layer rebuilds each animation tick.
class _ExpandedPlayerMotion extends StatelessWidget {
  const _ExpandedPlayerMotion({
    required this.sheetMotionT,
    required this.screenHeight,
    required this.sheetOpacity,
    required this.semanticLabel,
    required this.child,
    this.collapseAnchorY = 0,
  });

  final double sheetMotionT;
  final double screenHeight;
  final double sheetOpacity;
  final String semanticLabel;
  final Widget child;

  /// When > 0, collapse travel ends with the sheet top at this Y (mini bar).
  final double collapseAnchorY;

  @override
  Widget build(BuildContext context) {
    final double t = sheetMotionT.clamp(0.0, 1.0);
    final double travel = collapseAnchorY > 0
        ? collapseAnchorY
        : screenHeight;
    final double offsetY = travel * (1 - t);
    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Transform.translate(
          offset: Offset(0, offsetY),
          child: Opacity(
            opacity: sheetOpacity.clamp(0.0, 1.0),
            child: SizedBox(
              height: screenHeight,
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the mini player organism with swipe-to-dismiss gesture handling
/// and the dismiss translation animation. Kept separate so the heavy
/// `AnimatedBuilder` subtree rebuilds only when the dismiss controller
/// ticks, not on every state rebuild of the parent.
class _MiniPlayerTransition extends StatelessWidget {
  const _MiniPlayerTransition({
    required this.progress,
    required this.audio,
    this.useHeroArtwork = false,
    required this.identityChromeOpacity,
    required this.dismissAnimController,
    required this.dismissAnimation,
    required this.dismissOffsetY,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onTap,
    required this.onClose,
  });

  final double progress;
  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final AnimationController dismissAnimController;
  final Animation<double>? dismissAnimation;
  final double dismissOffsetY;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: progress > context.tokens.playerIgnorePointerThreshold,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        child: AnimatedBuilder(
          animation: dismissAnimController,
          builder: (context, child) {
            final offset = dismissAnimation?.value ?? dismissOffsetY;
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: _MiniPlayerOrganism(
            audio: audio,
            useHeroArtwork: useHeroArtwork,
            identityChromeOpacity: identityChromeOpacity,
            onTap: onTap,
            onClose: onClose,
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerOrganism extends StatelessWidget {
  const _MiniPlayerOrganism({
    required this.audio,
    this.useHeroArtwork = false,
    required this.identityChromeOpacity,
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return TilawaContentBounds(
      kind: TilawaContentKind.settings,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceTiny,
          tokens.spaceLarge,
          0,
        ),
        child: _YtMusicMiniPlayer(
          audio: audio,
          useHeroArtwork: useHeroArtwork,
          identityChromeOpacity: identityChromeOpacity,
          onTap: onTap,
          onClose: onClose,
        ),
      ),
    );
  }
}

/// Themed colors for the expanded now-playing stage (not the queue sheet).
@immutable
class _ExpandedPlayerPalette {
  const _ExpandedPlayerPalette({
    required this.foreground,
    required this.secondary,
    required this.disabled,
    required this.pillBackground,
    required this.artworkBackground,
    required this.artworkIcon,
    required this.playButtonBackground,
    required this.playButtonIcon,
    required this.playButtonGlow,
    required this.seekActive,
    required this.seekBuffered,
    required this.seekInactive,
    required this.artOverlay,
  });

  final Color foreground;
  final Color secondary;
  final Color disabled;
  final Color pillBackground;
  final Color artworkBackground;
  final Color artworkIcon;
  final Color playButtonBackground;
  final Color playButtonIcon;
  final Color playButtonGlow;
  final Color seekActive;
  final Color seekBuffered;
  final Color seekInactive;
  final Color artOverlay;

  factory _ExpandedPlayerPalette.resolve(
    BuildContext context, {
    required bool onImageBackdrop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final barTokens = theme.componentTokens.mediaPlayerBar;
    final bgTokens = theme.componentTokens.playerBackground;

    if (onImageBackdrop) {
      return _ExpandedPlayerPalette(
        foreground: colorScheme.onInverseSurface,
        secondary: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacityEmphasis,
        ),
        disabled: colorScheme.onInverseSurface.withValues(
          alpha: barTokens.disabledControlOpacity,
        ),
        pillBackground: colorScheme.onInverseSurface.withValues(alpha: 0.12),
        artworkBackground: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacitySubtle,
        ),
        artworkIcon: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacityEmphasis / 3,
        ),
        playButtonBackground: colorScheme.onInverseSurface,
        playButtonIcon: colorScheme.surface,
        playButtonGlow: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacityMedium,
        ),
        seekActive: colorScheme.onInverseSurface,
        seekBuffered: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacityMedium,
        ),
        seekInactive: colorScheme.onInverseSurface.withValues(
          alpha: tokens.opacitySubtle,
        ),
        artOverlay: bgTokens.overlayColor.withValues(
          alpha: bgTokens.defaultOverlayOpacity,
        ),
      );
    }

    return _ExpandedPlayerPalette(
      foreground: colorScheme.onSurface,
      secondary: colorScheme.onSurfaceVariant,
      disabled: colorScheme.onSurfaceVariant.withValues(
        alpha: barTokens.disabledControlOpacity,
      ),
      pillBackground: colorScheme.surfaceContainerHigh,
      artworkBackground: barTokens.artworkPlaceholderColor,
      artworkIcon: colorScheme.onSurfaceVariant,
      playButtonBackground: colorScheme.primary,
      playButtonIcon: colorScheme.onPrimary,
      playButtonGlow: colorScheme.primary.withValues(
        alpha: tokens.opacityMedium,
      ),
      seekActive: colorScheme.primary,
      seekBuffered: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
      seekInactive: barTokens.progressTrackBackgroundColor,
      artOverlay: bgTokens.overlayColor.withValues(
        alpha: bgTokens.defaultOverlayOpacity,
      ),
    );
  }

  static _ExpandedPlayerPalette of(BuildContext context) =>
      _ExpandedPlayerScope.paletteOf(context);
}

class _ExpandedPlayerScope extends InheritedWidget {
  const _ExpandedPlayerScope({
    required this.palette,
    required super.child,
  });

  final _ExpandedPlayerPalette palette;

  static _ExpandedPlayerPalette paletteOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ExpandedPlayerScope>()!
      .palette;

  @override
  bool updateShouldNotify(_ExpandedPlayerScope oldWidget) =>
      oldWidget.palette != palette;
}

class _ExpandedPlayerOrganism extends StatefulWidget {
  const _ExpandedPlayerOrganism({
    required this.state,
    required this.audio,
    required this.onCollapse,
    required this.onDismiss,
    required this.expandAnimation,
    this.useHeroArtwork = false,
    this.onPlayerExpandDragStart,
    this.onPlayerExpandDragUpdate,
    this.onPlayerExpandDragEnd,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final Animation<double> expandAnimation;
  final bool useHeroArtwork;
  final VoidCallback? onPlayerExpandDragStart;
  final ValueChanged<double>? onPlayerExpandDragUpdate;
  final ValueChanged<DragEndDetails>? onPlayerExpandDragEnd;

  @override
  State<_ExpandedPlayerOrganism> createState() =>
      _ExpandedPlayerOrganismState();
}

class _ExpandedPlayerOrganismState extends State<_ExpandedPlayerOrganism> {
  static const double _queuePeekSize = 0.20;
  static const double _queueMidSize = 0.48;
  static const double _queueFullSize = 0.90;

  final DraggableScrollableController _queueController =
      DraggableScrollableController();

  double? _lastExpandValue;

  bool _queueHandleDragMoved = false;
  bool _suppressQueueHandleTap = false;

  /// Positive [dy] = finger moved down (sheet shrinks).
  double _queueHandleDragNetDy = 0;
  double _stageDragNetDy = 0;

  DateTime? _lastQueueSizeLogAt;
  double? _lastLoggedQueueSize;

  @override
  void initState() {
    super.initState();
    _queueController.addListener(_onQueueSheetChanged);
    widget.expandAnimation.addListener(_onExpandAnimationTick);
    _lastExpandValue = widget.expandAnimation.value;
  }

  @override
  void dispose() {
    widget.expandAnimation.removeListener(_onExpandAnimationTick);
    _queueController.removeListener(_onQueueSheetChanged);
    _queueController.dispose();
    super.dispose();
  }

  void _onQueueSheetChanged() {
    if (!mounted) {
      return;
    }
    final bool attached = _queueController.isAttached;
    final double? size = attached ? _queueController.size : null;
    _maybeLogQueueSize(size, attached);
  }

  void _maybeLogQueueSize(
    double? size,
    bool attached,
  ) {
    if (!attached || size == null) {
      return;
    }
    final DateTime now = DateTime.now();
    final bool sizeJump =
        _lastLoggedQueueSize == null ||
        (size - _lastLoggedQueueSize!).abs() >= 0.03;
    final bool timeElapsed =
        _lastQueueSizeLogAt == null ||
        now.difference(_lastQueueSizeLogAt!) >
            const Duration(milliseconds: 250);
    if (!sizeJump && !timeElapsed) {
      return;
    }
    _lastLoggedQueueSize = size;
    _lastQueueSizeLogAt = now;
    QuranPlayerDebugLog.log(
      'queue.size',
      <String, Object?>{
        'size': size.toStringAsFixed(3),
        'reveal': _queueReveal.toStringAsFixed(3),
        'atPeek': _queueAtPeek,
      },
    );
  }

  void _suppressHandleTapBriefly() {
    _suppressQueueHandleTap = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _suppressQueueHandleTap = false;
      }
    });
  }

  void _onQueueHandleDragStart() {
    _queueHandleDragMoved = false;
    _queueHandleDragNetDy = 0;
    if (_queueAtPeek) {
      widget.onPlayerExpandDragStart?.call();
    }
  }

  void _onQueueHandleDragUpdate(
    double deltaDy, {
    required double sheetParentHeight,
    required List<double> snapSizes,
  }) {
    _queueHandleDragNetDy += deltaDy;
    if (deltaDy.abs() > 2) {
      _queueHandleDragMoved = true;
    }
    if (_queueAtPeek && deltaDy > 0) {
      widget.onPlayerExpandDragUpdate?.call(deltaDy);
      return;
    }
    _QueueSheetSnap.applyDragDelta(
      controller: _queueController,
      sheetParentHeight: sheetParentHeight,
      snapSizes: snapSizes,
      deltaDy: deltaDy,
    );
  }

  void _onQueueHandleDragEnd(DragEndDetails details) {
    if (_queueHandleDragMoved) {
      _suppressHandleTapBriefly();
    }
    _queueHandleDragMoved = false;

    final double velocity = details.primaryVelocity ?? 0;
    final double dismissVelocity = Theme.of(
      context,
    ).tokens.playerDismissVelocityThreshold;
    final double netDy = _queueHandleDragNetDy;
    _queueHandleDragNetDy = 0;

    if (_queueAtPeek && netDy > 0.5) {
      widget.onPlayerExpandDragEnd?.call(details);
      return;
    }

    if (velocity > dismissVelocity &&
        _queueReveal > _YtMusicNowPlayingStage.queueControlsFocusThreshold) {
      _collapseQueueSheetToPeek();
      return;
    }

    if (_queueController.isAttached) {
      _QueueSheetSnap.snapAfterRelease(
        controller: _queueController,
        snapSizes: const <double>[
          _queuePeekSize,
          _queueMidSize,
          _queueFullSize,
        ],
        releaseVelocity: velocity,
        netDragDy: netDy,
      );
    }
  }

  void _onStageDragStart() {
    _stageDragNetDy = 0;
    if (_queueAtPeek) {
      widget.onPlayerExpandDragStart?.call();
    }
  }

  void _onStageDragUpdate(double deltaDy) {
    _stageDragNetDy += deltaDy;
  }

  void _onStageDragEnd(DragEndDetails details) {
    if (!_queueController.isAttached) {
      return;
    }
    const List<double> snapSizes = <double>[
      _queuePeekSize,
      _queueMidSize,
      _queueFullSize,
    ];
    _QueueSheetSnap.snapAfterRelease(
      controller: _queueController,
      snapSizes: snapSizes,
      releaseVelocity: details.primaryVelocity ?? 0,
      netDragDy: _stageDragNetDy,
    );
    _stageDragNetDy = 0;
  }

  void _onQueueHandleTap() {
    if (_suppressQueueHandleTap) {
      QuranPlayerDebugLog.log('queue.handleTap.ignored');
      return;
    }
    if (_queueReveal > _YtMusicNowPlayingStage.queueControlsFocusThreshold) {
      QuranPlayerDebugLog.log('queue.handleTap.collapse');
      _collapseQueueSheetToPeek();
      return;
    }
    if (_queueController.isAttached &&
        _QueueSheetSnap.isAtPeek(
          controller: _queueController,
          peekSize: _queuePeekSize,
        )) {
      QuranPlayerDebugLog.log(
        'queue.handleTap.expandToMid',
        <String, Object?>{'to': _queueMidSize},
      );
      _queueController.animateTo(
        _queueMidSize,
        duration: _QueueSheetSnap.animationDuration,
        curve: _QueueSheetSnap.animationCurve,
      );
      return;
    }
    QuranPlayerDebugLog.log('queue.handleTap.toggle');
    _QueueSheetSnap.toggleMinMax(
      controller: _queueController,
      snapSizes: const <double>[
        _queuePeekSize,
        _queueMidSize,
        _queueFullSize,
      ],
    );
  }

  void _collapseQueueSheetToPeek() {
    _suppressHandleTapBriefly();
    QuranPlayerDebugLog.log(
      'queue.collapseToPeek',
      <String, Object?>{
        'size': _queueController.isAttached
            ? _queueController.size.toStringAsFixed(3)
            : null,
        'reveal': _queueReveal.toStringAsFixed(3),
      },
    );
    if (!_queueController.isAttached) {
      return;
    }
    _queueController.animateTo(
      _queuePeekSize,
      duration: _QueueSheetSnap.animationDuration,
      curve: _QueueSheetSnap.animationCurve,
    );
  }

  void _onExpandAnimationTick() {
    final double value = widget.expandAnimation.value;
    final double? last = _lastExpandValue;
    _lastExpandValue = value;
    if (last == null || last >= 1.0 || value < 1.0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _queueController.isAttached) {
        QuranPlayerDebugLog.log(
          'queue.resetOnPlayerExpand',
          <String, Object?>{'peekSize': _queuePeekSize},
        );
        _queueController.jumpTo(_queuePeekSize);
      }
    });
  }

  double get _queueReveal {
    if (!_queueController.isAttached) {
      return 0;
    }
    return ((_queueController.size - _queuePeekSize) /
            (_queueFullSize - _queuePeekSize))
        .clamp(0.0, 1.0);
  }

  bool get _queueAtPeek => !_queueController.isAttached || _queueReveal < 0.04;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final PlayerBackgroundState bgState = context
        .watch<PlayerBackgroundCubit>()
        .state;
    final bool hasCustomBackground =
        bgState.config.type == PlayerBackgroundType.custom &&
        bgState.config.customImagePath != null;
    final bool onImageBackdrop =
        hasCustomBackground || widget.audio.artUri != null;
    final _ExpandedPlayerPalette palette = _ExpandedPlayerPalette.resolve(
      context,
      onImageBackdrop: onImageBackdrop,
    );
    final Brightness statusBarIconBrightness =
        theme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    final Color queueSheetColor = quranPlayerQueueSheetColor(colorScheme);
    final Brightness navBarIconBrightness =
        ThemeData.estimateBrightnessForColor(queueSheetColor) == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return _ExpandedPlayerScope(
      palette: palette,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarIconBrightness,
          statusBarBrightness: statusBarIconBrightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: queueSheetColor,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarIconBrightness: navBarIconBrightness,
        ),
        child: Material(
          color: colorScheme.surface,
          elevation: tokens.spaceSmall,
          shape: const RoundedRectangleBorder(),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const PlayerBackgroundLayer(),
              Positioned.fill(
                child:
                    BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
                      builder: (context, bgState) {
                        if (bgState.config.type ==
                            PlayerBackgroundType.custom) {
                          return const SizedBox.shrink();
                        }
                        if (widget.audio.artUri == null) {
                          return const SizedBox.shrink();
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.audio.artUri!,
                              fit: BoxFit.cover,
                            ),
                            ColoredBox(color: palette.artOverlay),
                          ],
                        );
                      },
                    ),
              ),
              if (isLandscape)
                _ExpandedPlayerLandscape(
                  state: widget.state,
                  audio: widget.audio,
                  onCollapse: widget.onCollapse,
                  onDismiss: widget.onDismiss,
                  onPlayerExpandDragStart: widget.onPlayerExpandDragStart,
                  onPlayerExpandDragUpdate: widget.onPlayerExpandDragUpdate,
                  onPlayerExpandDragEnd: widget.onPlayerExpandDragEnd,
                )
              else
                Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: MediaQuery.paddingOf(context).bottom,
                      child: ColoredBox(color: queueSheetColor),
                    ),
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: TilawaContentBounds(
                          kind: TilawaContentKind.media,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const List<double> snapSizes = <double>[
                                _queuePeekSize,
                                _queueMidSize,
                                _queueFullSize,
                              ];
                              return ListenableBuilder(
                                listenable: Listenable.merge(
                                  <Listenable>[
                                    _queueController,
                                    widget.expandAnimation,
                                  ],
                                ),
                                builder: (context, _) {
                                  final double expandProgress =
                                      widget.expandAnimation.value;
                                  final PlayerExpandTransitionMetrics
                                  expandMetrics =
                                      PlayerExpandTransitionMetrics.compute(
                                        progress: expandProgress,
                                        miniPlayerHeight: 0,
                                      );
                                  final double sheetHeight =
                                      _queueController.isAttached
                                      ? _queueController.size *
                                            constraints.maxHeight
                                      : _queuePeekSize * constraints.maxHeight;
                                  final double stageBottomInset =
                                      sheetHeight * expandMetrics.queueChromeT;
                                  final double queueReveal =
                                      expandMetrics.queueChromeT < 0.5
                                      ? 0
                                      : _queueReveal;

                                  final Widget stage = _YtMusicNowPlayingStage(
                                    state: widget.state,
                                    audio: widget.audio,
                                    queueReveal: queueReveal,
                                    onCollapse: widget.onCollapse,
                                    useHeroArtwork: widget.useHeroArtwork,
                                  );

                                  return Stack(
                                    children: [
                                      // Sheet first so the stage (header buttons)
                                      // stays above it for hit testing.
                                      Visibility(
                                        visible:
                                            expandMetrics.queueChromeT > 0.01,
                                        maintainState: true,
                                        maintainAnimation: true,
                                        child: Opacity(
                                          opacity: expandMetrics.queueChromeT,
                                          child: IgnorePointer(
                                            ignoring:
                                                expandMetrics.queueChromeT <
                                                0.5,
                                            child: DraggableScrollableSheet(
                                              controller: _queueController,
                                              initialChildSize: _queuePeekSize,
                                              minChildSize: _queuePeekSize,
                                              maxChildSize: _queueFullSize,
                                              snap: true,
                                              snapSizes: snapSizes,
                                              builder:
                                                  (
                                                    context,
                                                    scrollController,
                                                  ) {
                                                    return _PlayerQueueSheet(
                                                      scrollController:
                                                          scrollController,
                                                      queueController:
                                                          _queueController,
                                                      sheetParentHeight:
                                                          constraints
                                                              .maxHeight,
                                                      peekSize: _queuePeekSize,
                                                      snapSizes: snapSizes,
                                                      state: widget.state,
                                                      currentAudio:
                                                          widget.audio,
                                                      onCollapseToPeek:
                                                          _collapseQueueSheetToPeek,
                                                      onHandleTap:
                                                          _onQueueHandleTap,
                                                      onHandleDragStart:
                                                          _onQueueHandleDragStart,
                                                      onHandleDragUpdate:
                                                          _onQueueHandleDragUpdate,
                                                      onHandleDragEnd:
                                                          _onQueueHandleDragEnd,
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        bottom: stageBottomInset,
                                        child:
                                            expandMetrics.queueChromeT < 0.5 ||
                                                _queueAtPeek
                                            ? GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onVerticalDragStart: (_) {
                                                  _onStageDragStart();
                                                  QuranPlayerDebugLog.log(
                                                    'queue.stageDragStart',
                                                    <String, Object?>{
                                                      'atPeek': _queueAtPeek,
                                                    },
                                                  );
                                                },
                                                onVerticalDragUpdate:
                                                    (
                                                      details,
                                                    ) {
                                                      final double dy =
                                                          details.delta.dy;
                                                      _onStageDragUpdate(dy);
                                                      if (dy > 0) {
                                                        widget
                                                            .onPlayerExpandDragUpdate
                                                            ?.call(dy);
                                                        return;
                                                      }
                                                      if (dy < 0) {
                                                        _QueueSheetSnap.applyDragDelta(
                                                          controller:
                                                              _queueController,
                                                          sheetParentHeight:
                                                              constraints
                                                                  .maxHeight,
                                                          snapSizes: snapSizes,
                                                          deltaDy: dy,
                                                        );
                                                      }
                                                    },
                                                onVerticalDragEnd: (details) {
                                                  QuranPlayerDebugLog.log(
                                                    'queue.stageDragEnd',
                                                    <String, Object?>{
                                                      'velocity':
                                                          (details.primaryVelocity ??
                                                                  0)
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                      'size':
                                                          _queueController
                                                              .isAttached
                                                          ? _queueController
                                                                .size
                                                                .toStringAsFixed(
                                                                  3,
                                                                )
                                                          : null,
                                                    },
                                                  );
                                                  if (_queueAtPeek &&
                                                      _stageDragNetDy.abs() >
                                                          0.5) {
                                                    widget
                                                        .onPlayerExpandDragEnd
                                                        ?.call(details);
                                                    _stageDragNetDy = 0;
                                                    return;
                                                  }
                                                  if (_stageDragNetDy < -0.5) {
                                                    _onStageDragEnd(details);
                                                    _stageDragNetDy = 0;
                                                    return;
                                                  }
                                                  _onStageDragEnd(details);
                                                },
                                                child: stage,
                                              )
                                            : stage,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Now-playing body that shrinks and fades as the queue sheet slides up.
class _YtMusicNowPlayingStage extends StatelessWidget {
  const _YtMusicNowPlayingStage({
    required this.state,
    required this.audio,
    required this.queueReveal,
    required this.onCollapse,
    this.useHeroArtwork = false,
  });

  /// Artwork hides; controls + history show in the upper stage.
  static const double queueControlsFocusThreshold = 0.08;

  /// Thin strip when the queue nears full height.
  static const double compactBarThreshold = 0.62;

  final AudioPlayerState state;
  final AudioEntity audio;
  final double queueReveal;
  final VoidCallback onCollapse;
  final bool useHeroArtwork;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool tightStage = constraints.maxHeight < 140;
        final bool showCompactBar =
            queueReveal > compactBarThreshold || tightStage;
        final bool showQueueFocused =
            queueReveal > queueControlsFocusThreshold && !showCompactBar;

        if (showCompactBar) {
          return _CompactNowPlayingBar(
            audio: audio,
            state: state,
            onCollapse: onCollapse,
            opacity: showCompactBar && !tightStage
                ? ((queueReveal - compactBarThreshold) / 0.25).clamp(0.0, 1.0)
                : 1.0,
          );
        }

        if (showQueueFocused) {
          final tokens = Theme.of(context).tokens;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
                _PlayerReciterHistorySection(audio: audio, state: state),
                _PlayerPlaybackCluster(
                  state: state,
                  queueReveal: queueReveal,
                ),
                SizedBox(height: tokens.spaceSmall),
              ],
            ),
          );
        }

        final tokens = Theme.of(context).tokens;
        final PlayerExpandTransitionMetrics? expandMetrics =
            PlayerExpandMetricsScope.maybeOf(context);
        final double stageChromeOpacity =
            expandMetrics?.stageChromeOpacity ?? 1;

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
            Expanded(
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceLarge,
                      ),
                      child: Opacity(
                        opacity: stageChromeOpacity.clamp(0.0, 1.0),
                        child: Column(
                          mainAxisAlignment: .center,
                          mainAxisSize: .min,
                          spacing: tokens.spaceLarge,
                          children: [
                            _PlayerArtAtom(
                              audioId: audio.id,
                              artUri: audio.artUri,
                              useHeroArtwork: useHeroArtwork,
                            ),
                            _PlayerMetadataMolecule(
                              title: audio.title,
                              artist: audio.artist,
                              centerAlign: true,
                              audioId: audio.id,
                              useHeroMetadata: useHeroArtwork,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _PlayerPlaybackCluster(
                    state: state,
                    queueReveal: queueReveal,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Loads reciter listening history for the expanded player queue-focused layout.
class _PlayerReciterHistorySection extends StatefulWidget {
  const _PlayerReciterHistorySection({
    required this.audio,
    required this.state,
  });

  final AudioEntity audio;
  final AudioPlayerState state;

  @override
  State<_PlayerReciterHistorySection> createState() =>
      _PlayerReciterHistorySectionState();
}

class _PlayerReciterHistorySectionState
    extends State<_PlayerReciterHistorySection> {
  Future<List<HistoryEntity>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _reloadHistory();
  }

  @override
  void didUpdateWidget(covariant _PlayerReciterHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio.id != widget.audio.id) {
      _reloadHistory();
    }
  }

  void _reloadHistory() {
    final String? reciterId = widget.audio.extras?['reciterId'] as String?;
    if (reciterId == null || reciterId.isEmpty) {
      _historyFuture = Future<List<HistoryEntity>>.value(
        const <HistoryEntity>[],
      );
      return;
    }
    _historyFuture = getIt<GetHistoryByReciterUseCase>()(reciterId).then(
      (result) => result.fold(
        (_) => const <HistoryEntity>[],
        (List<HistoryEntity> list) => list,
      ),
    );
  }

  void _onPlayHistory(HistoryEntity history) {
    HapticFeedback.lightImpact();
    final List<AudioEntity> queue =
        widget.state.playbackState?.queue ?? const <AudioEntity>[];
    final int index = queue.indexWhere((AudioEntity track) {
      final Object? surahId = track.extras?['surahId'];
      return surahId != null &&
          surahId.toString() == history.surahId.toString();
    });
    if (index < 0) {
      return;
    }
    final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
    bloc.add(AudioPlayerEvent.skipToQueueItem(index));
    if (history.lastPositionMs > 0 && !history.completed) {
      bloc.add(
        AudioPlayerEvent.seekTo(
          Duration(milliseconds: history.lastPositionMs),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryEntity>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final List<HistoryEntity> history =
            snapshot.data ?? const <HistoryEntity>[];
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(
            top: Theme.of(context).tokens.spaceSmall,
            bottom: Theme.of(context).tokens.spaceSmall,
          ),
          child: ReciterHistorySection(
            historyList: history,
            onPlay: _onPlayHistory,
          ),
        );
      },
    );
  }
}

/// Collapsed player strip shown when the queue sheet is fully raised.
class _CompactNowPlayingBar extends StatelessWidget {
  const _CompactNowPlayingBar({
    required this.audio,
    required this.state,
    required this.onCollapse,
    required this.opacity,
  });

  final AudioEntity audio;
  final AudioPlayerState state;
  final VoidCallback onCollapse;
  final double opacity;

  static const BoxConstraints _iconConstraints = BoxConstraints(
    minWidth: 40,
    minHeight: 40,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w600,
          height: 1.15,
        );
    final TextStyle? artistStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(
          color: palette.secondary,
          height: 1.15,
        );

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocSelector<AudioPlayerBloc, AudioPlayerState, double>(
            selector: (state) => _MiniPlayerSnapshot.fromState(state).progress,
            builder: (context, progress) {
              return LinearProgressIndicator(
                value: progress,
                backgroundColor: palette.seekInactive,
                valueColor: AlwaysStoppedAnimation<Color>(palette.seekActive),
                minHeight: tokens.progressHeight,
              );
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceSmall,
              vertical: tokens.spaceExtraSmall,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  constraints: _iconConstraints,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    FluentIcons.chevron_down_24_regular,
                    color: palette.foreground,
                    size: tokens.iconSizeLarge,
                  ),
                  onPressed: onCollapse,
                ),
                _MiniArtwork(artUri: audio.artUri, size: 40),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      Text(
                        audio.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      Text(
                        audio.artist ?? context.l10n.unknownReciter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: artistStyle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: _iconConstraints,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    state.isPlaying
                        ? FluentIcons.pause_24_filled
                        : FluentIcons.play_24_filled,
                    color: palette.foreground,
                    size: tokens.iconSizeLarge,
                  ),
                  onPressed: () {
                    context.read<AudioPlayerBloc>().add(
                      state.isPlaying
                          ? const AudioPlayerEvent.pauseAudio()
                          : const AudioPlayerEvent.playAudio(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedPlayerLandscape extends StatelessWidget {
  const _ExpandedPlayerLandscape({
    required this.state,
    required this.audio,
    required this.onCollapse,
    required this.onDismiss,
    this.onPlayerExpandDragStart,
    this.onPlayerExpandDragUpdate,
    this.onPlayerExpandDragEnd,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final VoidCallback? onPlayerExpandDragStart;
  final ValueChanged<double>? onPlayerExpandDragUpdate;
  final ValueChanged<DragEndDetails>? onPlayerExpandDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => onPlayerExpandDragStart?.call(),
        onVerticalDragUpdate: (DragUpdateDetails details) {
          onPlayerExpandDragUpdate?.call(details.delta.dy);
        },
        onVerticalDragEnd: onPlayerExpandDragEnd,
        child: SafeArea(
          child: Stack(
          children: [
            // Header: Metadata and Navigation
            Positioned(
              top: tokens.spaceSmall,
              left: isRtl ? null : tokens.spaceMedium,
              right: isRtl ? tokens.spaceMedium : null,
              child: Row(
                spacing: tokens.spaceSmall,
                children: [
                  IconButton(
                    icon: Icon(
                      FluentIcons.chevron_down_24_regular,
                      color: palette.foreground,
                      size: tokens.iconSizeLarge,
                    ),
                    onPressed: onCollapse,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      Text(
                        audio.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.foreground,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audio.artist ?? context.l10n.unknownReciter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              top: tokens.spaceSmall,
              left: isRtl ? tokens.spaceMedium : null,
              right: isRtl ? null : tokens.spaceMedium,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      FluentIcons.image_24_regular,
                      color: palette.foreground,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BackgroundSourceDialog(
                          onSourceSelected: (source) {
                            context.read<PlayerBackgroundCubit>().pickImage(
                              source,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Semantics(
                    identifier: QuranPlayerSemanticsIds.expandedMoreMenu,
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        FluentIcons.more_vertical_24_regular,
                        color: palette.foreground,
                      ),
                      onPressed: () => _showExpandedPlayerMenu(context, state),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: tokens.spaceSmall + tokens.spaceExtraLarge,
              child: _PlayerPlaybackCluster(state: state),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Molecules
// ---------------------------------------------------------------------------

class _YtMusicPlayerHeader extends StatelessWidget {
  const _YtMusicPlayerHeader({
    required this.state,
    required this.onCollapse,
  });

  final AudioPlayerState state;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
      child: Row(
        children: [
          Semantics(
            identifier: QuranPlayerSemanticsIds.expandedCollapseButton,
            button: true,
            child: IconButton(
              icon: Icon(
                FluentIcons.chevron_down_24_regular,
                color: palette.foreground,
                size: tokens.iconSizeLarge,
              ),
              onPressed: onCollapse,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const Spacer(),
          Semantics(
            identifier: QuranPlayerSemanticsIds.expandedMoreMenu,
            button: true,
            child: IconButton(
              icon: Icon(
                FluentIcons.more_vertical_24_regular,
                color: palette.foreground,
              ),
              onPressed: () => _showExpandedPlayerMenu(context, state),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showExpandedPlayerMenu(
  BuildContext context,
  AudioPlayerState state,
) async {
  await showTilawaModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final bool sleepEnabled = context
          .read<SettingsCubit>()
          .state
          .isSleepTimerEnabled;
      return Padding(
        padding: EdgeInsets.only(bottom: sheetContext.floatingBottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            if (sleepEnabled)
              Semantics(
                identifier: QuranPlayerSemanticsIds.menuSheetSleepTimer,
                button: true,
                child: ListTile(
                  leading: Icon(
                    state.isSleepTimerActive
                        ? FluentIcons.timer_24_filled
                        : FluentIcons.timer_24_regular,
                  ),
                  title: Text(sheetContext.l10n.recitationDuration),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  },
                ),
              ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.menuSheetBackground,
              button: true,
              child: ListTile(
                leading: const Icon(FluentIcons.image_24_regular),
                title: Text(sheetContext.l10n.chooseBackgroundSource),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showDialog(
                    context: context,
                    builder: (dialogContext) => BackgroundSourceDialog(
                      onSourceSelected: (source) {
                        context.read<PlayerBackgroundCubit>().pickImage(source);
                      },
                    ),
                  );
                },
              ),
            ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.menuSheetStop,
              button: true,
              child: ListTile(
                leading: const Icon(FluentIcons.stop_24_regular),
                title: Text(sheetContext.l10n.stopPlayback),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (getIt<PlayerPresentationController>().routeOpen) {
                    getIt<PlayerPresentationController>().collapse();
                  }
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.stopAudio(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Progress, transport, and adjustment pills pinned as one control band.
class _PlayerPlaybackCluster extends StatelessWidget {
  const _PlayerPlaybackCluster({
    required this.state,
    this.queueReveal = 0,
  });

  final AudioPlayerState state;
  final double queueReveal;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double queueInset = tokens.spaceMedium * queueReveal.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExpandedProgressBar(),
        SizedBox(height: tokens.spaceSmall),
        _PlayerTransportRow(
          state: state,
          isPlaying: state.isPlaying,
        ),
        SizedBox(height: tokens.spaceMedium),
        _PlayerActionPillsMolecule(state: state),
        SizedBox(height: tokens.spaceSmall + queueInset),
      ],
    );
  }
}

class _PlayerMetadataMolecule extends StatelessWidget {
  const _PlayerMetadataMolecule({
    required this.title,
    this.artist,
    this.centerAlign = false,
    this.audioId,
    this.useHeroMetadata = false,
  });

  final String title;
  final String? artist;
  final bool centerAlign;
  final String? audioId;
  final bool useHeroMetadata;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final TextStyle? titleStyle = context
        .responsiveStyle((t) => t.titleLarge)
        ?.copyWith(color: palette.foreground, fontWeight: FontWeight.w600);
    final TextStyle? subtitleStyle = context
        .responsiveStyle((t) => t.bodyMedium)
        ?.copyWith(color: palette.secondary);
    final String subtitle = artist ?? context.l10n.unknownReciter;

    if (useHeroMetadata && audioId != null && titleStyle != null) {
      return QuranPlayerHeroMetadata(
        audioId: audioId!,
        title: title,
        subtitle: subtitle,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle ?? const TextStyle(),
        centerAlign: centerAlign,
        semanticDestination: true,
      );
    }

    final TextAlign textAlign = centerAlign
        ? TextAlign.center
        : TextAlign.start;
    final CrossAxisAlignment crossAlign = centerAlign
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.stretch;
    return Column(
      crossAxisAlignment: crossAlign,
      spacing: tokens.spaceExtraSmall,
      children: [
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackTitle,
          child: Text(
            title,
            style: titleStyle,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
          child: Text(
            subtitle,
            style: subtitleStyle,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PlayerTransportRow extends StatelessWidget {
  const _PlayerTransportRow({
    required this.state,
    required this.isPlaying,
  });

  final AudioPlayerState state;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final bool shuffleOn = QuranPlayerTransportControls.shuffleActive(
      state.shuffleMode,
    );
    final Color enabled = palette.foreground;
    final Color disabled = palette.disabled;
    final IconData repeatIcon = QuranPlayerTransportControls.repeatIcon(
      state.repeatMode,
    );
    final bool repeatActive = QuranPlayerTransportControls.repeatActive(
      state.repeatMode,
    );
    final IconData shuffleIcon = QuranPlayerTransportControls.shuffleIcon(
      state.shuffleMode,
    );
    final bool swapSkipSidesForArabic = context.isArabic;

    final Widget previousControl = Semantics(
      identifier: QuranPlayerSemanticsIds.transportPrevious,
      button: true,
      child: IconButton(
        icon: Icon(
          swapSkipSidesForArabic ? Icons.skip_next : Icons.skip_previous,
          color: state.canGoPrevious ? enabled : disabled,
          size: tokens.iconSizeLarge,
        ),
        onPressed: state.canGoPrevious
            ? () => context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.skipToPrevious(),
              )
            : null,
      ),
    );
    final Widget nextControl = Semantics(
      identifier: QuranPlayerSemanticsIds.transportNext,
      button: true,
      child: IconButton(
        icon: Icon(
          swapSkipSidesForArabic ? Icons.skip_previous : Icons.skip_next,
          color: state.canGoNext ? enabled : disabled,
          size: tokens.iconSizeLarge,
        ),
        onPressed: state.canGoNext
            ? () => context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.skipToNext(),
              )
            : null,
      ),
    );

    // App locale is RTL for Arabic; keep transport LTR so skip sides do not
    // mirror twice (Row flip would undo the Arabic-only swap).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportShuffle,
            button: true,
            child: IconButton(
              icon: Icon(
                shuffleIcon,
                color: shuffleOn ? enabled : disabled,
                size: tokens.iconSizeLarge,
              ),
              onPressed: () {
                context.read<AudioPlayerBloc>().add(
                  AudioPlayerEvent.setShuffleMode(
                    QuranPlayerTransportControls.nextShuffleMode(
                      state.shuffleMode,
                    ),
                  ),
                );
              },
              tooltip: context.l10n.shufflePlaylist,
            ),
          ),
          if (swapSkipSidesForArabic) nextControl else previousControl,
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportPlayPause,
            button: true,
            child: _PlayerPlayPauseAtom(
              isPlaying: isPlaying,
              onTap: () {
                context.read<AudioPlayerBloc>().add(
                  isPlaying
                      ? const AudioPlayerEvent.pauseAudio()
                      : const AudioPlayerEvent.playAudio(),
                );
              },
            ),
          ),
          if (swapSkipSidesForArabic) previousControl else nextControl,
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportRepeat,
            button: true,
            child: IconButton(
              icon: Icon(
                repeatIcon,
                color: repeatActive ? enabled : disabled,
                size: tokens.iconSizeLarge,
              ),
              onPressed: () {
                context.read<AudioPlayerBloc>().add(
                  AudioPlayerEvent.setRepeatMode(
                    QuranPlayerTransportControls.nextRepeatMode(
                      state.repeatMode,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerActionPillsMolecule extends StatelessWidget {
  const _PlayerActionPillsMolecule({required this.state});

  final AudioPlayerState state;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final bool sleepEnabled = context
        .watch<SettingsCubit>()
        .state
        .isSleepTimerEnabled;
    return SizedBox(
      height: tokens.minInteractiveDimension,
      child: Row(
        mainAxisAlignment: .center,
        spacing: tokens.spaceSmall,
        children: [
          Semantics(
            identifier: QuranPlayerSemanticsIds.actionPillSpeed,
            button: true,
            child: _YtMusicActionPill(
              label: '${state.speed.toStringAsFixed(1)}x',
              icon: FluentIcons.gauge_24_regular,
              onTap: () {
                final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
                showSliderDialog(
                  context: context,
                  title: context.l10n.playbackSpeed,
                  divisions: 8,
                  min: 0.5,
                  max: 2.5,
                  value: state.speed,
                  onChanged: (double speed) {
                    bloc.add(AudioPlayerEvent.setSpeed(speed));
                  },
                );
              },
            ),
          ),
          Semantics(
            identifier: QuranPlayerSemanticsIds.actionPillVolume,
            button: true,
            child: _YtMusicActionPill(
              icon: FluentIcons.speaker_2_24_regular,
              onTap: () {
                final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
                showSliderDialog(
                  context: context,
                  title: context.l10n.adjustVolume,
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: state.volume,
                  onChanged: (double volume) {
                    bloc.add(AudioPlayerEvent.setVolume(volume));
                  },
                );
              },
            ),
          ),
          if (sleepEnabled) ...[
            Semantics(
              identifier: QuranPlayerSemanticsIds.actionPillSleepTimer,
              button: true,
              child: _YtMusicActionPill(
                icon: state.isSleepTimerActive
                    ? FluentIcons.timer_24_filled
                    : FluentIcons.timer_24_regular,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SleepTimerDialog(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _YtMusicActionPill extends StatelessWidget {
  const _YtMusicActionPill({
    this.label,
    required this.icon,
    required this.onTap,
  });

  final String? label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.pill,
      height: tokens.minInteractiveDimension,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: tokens.minInteractiveDimension,
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Material(
        color: palette.pillBackground,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              spacing: tokens.spaceExtraSmall,
              children: [
                Icon(
                  icon,
                  color: palette.foreground,
                  size: tokens.iconSizeMedium,
                ),
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

class _PlayerArtAtom extends StatelessWidget {
  const _PlayerArtAtom({
    this.audioId,
    this.artUri,
    this.maxHeight,
    this.useHeroArtwork = false,
  });

  final String? audioId;
  final String? artUri;
  final double? maxHeight;
  final bool useHeroArtwork;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final Widget artwork = useHeroArtwork && audioId != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width -
                      tokens.spaceLarge * 2;
              final double height = maxHeight ??
                  width * 9 / 16;
              return QuranPlayerHeroArtwork(
                audioId: audioId!,
                artUri: artUri,
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                size: Size(width, height),
                semanticDestination: true,
              );
            },
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            child: artUri != null
                ? CachedNetworkImage(
                    imageUrl: artUri!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildDefaultArt(context),
                  )
                : _buildDefaultArt(context),
          );

    final Widget sizedArt = useHeroArtwork && audioId != null
        ? artwork
        : maxHeight != null
        ? SizedBox(
            height: maxHeight,
            width: double.infinity,
            child: artwork,
          )
        : AspectRatio(aspectRatio: 16 / 9, child: artwork);

    if (useHeroArtwork) {
      return sizedArt;
    }

    return Semantics(
      identifier: QuranPlayerSemanticsIds.expandedArtwork,
      image: true,
      child: sizedArt,
    );
  }

  Widget _buildDefaultArt(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    return ColoredBox(
      color: palette.artworkBackground,
      child: Center(
        child: Icon(
          FluentIcons.music_note_2_24_filled,
          size: tokens.iconSizeLarge * 3.3, // approx 80
          color: palette.artworkIcon,
        ),
      ),
    );
  }
}

class _PlayerPlayPauseAtom extends StatelessWidget {
  const _PlayerPlayPauseAtom({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final buttonSize = tokens.iconSizeLarge * 3.3; // approx 80
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.playButtonBackground,
        boxShadow: [
          BoxShadow(
            color: palette.playButtonGlow,
            blurRadius: tokens.spaceLarge,
            spreadRadius: tokens.spaceTiny,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? FluentIcons.pause_48_filled : FluentIcons.play_48_filled,
          color: palette.playButtonIcon,
          size: tokens.iconSizeLarge * 1.6, // approx 40
        ),
        onPressed: onTap,
      ),
    );
  }
}

@immutable
class _MiniPlayerSnapshot {
  const _MiniPlayerSnapshot({
    required this.progress,
    required this.isPlaying,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isSleepTimerActive,
  });

  final double progress;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isSleepTimerActive;

  static _MiniPlayerSnapshot fromState(AudioPlayerState state) {
    final PositionData? data = state.positionData;
    final double progress = data == null || data.duration.inMilliseconds == 0
        ? 0.0
        : data.position.inMilliseconds / data.duration.inMilliseconds;
    return _MiniPlayerSnapshot(
      progress: progress.clamp(0.0, 1.0),
      isPlaying: state.isPlaying,
      canGoPrevious: state.canGoPrevious,
      canGoNext: state.canGoNext,
      isSleepTimerActive: state.isSleepTimerActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MiniPlayerSnapshot &&
          progress == other.progress &&
          isPlaying == other.isPlaying &&
          canGoPrevious == other.canGoPrevious &&
          canGoNext == other.canGoNext &&
          isSleepTimerActive == other.isSleepTimerActive;

  @override
  int get hashCode => Object.hash(
    progress,
    isPlaying,
    canGoPrevious,
    canGoNext,
    isSleepTimerActive,
  );
}

class _YtMusicMiniPlayer extends StatelessWidget {
  const _YtMusicMiniPlayer({
    required this.audio,
    this.useHeroArtwork = false,
    required this.identityChromeOpacity,
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, _MiniPlayerSnapshot>(
      selector: _MiniPlayerSnapshot.fromState,
      builder: (context, snapshot) {
        return _YtMusicMiniPlayerBody(
          audio: audio,
          useHeroArtwork: useHeroArtwork,
          snapshot: snapshot,
          identityChromeOpacity: identityChromeOpacity,
          onTap: onTap,
          onClose: onClose,
        );
      },
    );
  }
}

class _YtMusicMiniPlayerBody extends StatelessWidget {
  const _YtMusicMiniPlayerBody({
    required this.audio,
    this.useHeroArtwork = false,
    required this.snapshot,
    required this.identityChromeOpacity,
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final _MiniPlayerSnapshot snapshot;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final theme = Theme.of(context);
    final bool sleepTimerEnabled = context
        .watch<SettingsCubit>()
        .state
        .isSleepTimerEnabled;
    final String subtitle = audio.artist ?? context.l10n.unknownReciter;
    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: barTokens.titleFontWeight,
          color: theme.colorScheme.onSurface,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: barTokens.subtitleOpacity,
          ),
        );
    final Widget? artwork = audio.artUri == null
        ? null
        : useHeroArtwork
        ? QuranPlayerHeroArtwork(
            audioId: audio.id,
            artUri: audio.artUri,
            borderRadius: BorderRadius.circular(barTokens.artworkRadius),
            size: Size.square(barTokens.artworkSize),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(barTokens.artworkRadius),
            child: CachedNetworkImage(
              imageUrl: audio.artUri!,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          );

    final Widget? titleSubtitle = useHeroArtwork
        ? QuranPlayerHeroMetadata(
            audioId: audio.id,
            title: audio.title,
            subtitle: subtitle,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
          )
        : null;

    return Semantics(
      identifier: QuranPlayerSemanticsIds.miniPlayer,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TilawaMediaPlayerBar(
            layoutWidth: constraints.maxWidth,
            title: audio.title,
            subtitle: subtitle,
            titleSubtitle: titleSubtitle,
            artwork: artwork,
            identityChromeOpacity: identityChromeOpacity,
            progress: snapshot.progress,
            isPlaying: snapshot.isPlaying,
            canGoPrevious: snapshot.canGoPrevious,
            canGoNext: snapshot.canGoNext,
            isSleepTimerActive: snapshot.isSleepTimerActive,
            isSleepTimerEnabled: sleepTimerEnabled,
            onTap: onTap,
            onClose: onClose,
            playPauseSemanticIdentifier:
                QuranPlayerSemanticsIds.miniPlayerPlayPause,
            closeSemanticIdentifier: QuranPlayerSemanticsIds.miniPlayerClose,
            onPlayPause: () {
              context.read<AudioPlayerBloc>().add(
                snapshot.isPlaying
                    ? const AudioPlayerEvent.pauseAudio()
                    : const AudioPlayerEvent.playAudio(),
              );
            },
            onPrevious: snapshot.canGoPrevious
                ? () => context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.skipToPrevious(),
                  )
                : null,
            onNext: snapshot.canGoNext
                ? () => context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.skipToNext(),
                  )
                : null,
            onSleepTimerTap: sleepTimerEnabled
                ? () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  }
                : null,
            playTooltip: context.l10n.play,
            pauseTooltip: context.l10n.pause,
            previousTooltip: context.l10n.previous,
            nextTooltip: context.l10n.next,
            openPlayerSemanticLabel: audio.title,
          );
        },
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.artUri, required this.size});

  final String? artUri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
        child: artUri == null
            ? ColoredBox(
                color: barTokens.artworkPlaceholderColor,
                child: Icon(
                  FluentIcons.music_note_2_24_filled,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : CachedNetworkImage(
                imageUrl: artUri!,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Snap and drag helpers for the queue [DraggableScrollableSheet].
abstract final class _QueueSheetSnap {
  static const Duration animationDuration = Duration(milliseconds: 320);
  static const Curve animationCurve = Curves.easeOutCubic;
  static const double _peekEpsilon = 0.02;

  static bool isAtPeek({
    required DraggableScrollableController controller,
    required double peekSize,
  }) {
    if (!controller.isAttached) {
      return true;
    }
    return controller.size <= peekSize + _peekEpsilon;
  }

  static const double _releaseVelocityBiasThreshold = 150;
  static const double _netDragBiasThreshold = 20;

  /// Snaps using release velocity and net drag so a downward release does not
  /// jump back to the nearest higher snap (e.g. 0.79 → 0.9).
  static void snapAfterRelease({
    required DraggableScrollableController controller,
    required List<double> snapSizes,
    required double releaseVelocity,
    required double netDragDy,
  }) {
    if (!controller.isAttached || snapSizes.isEmpty) {
      return;
    }

    final List<double> sorted = List<double>.from(snapSizes)..sort();
    final double size = controller.size;

    bool collapseIntent =
        releaseVelocity > _releaseVelocityBiasThreshold ||
        netDragDy > _netDragBiasThreshold;
    bool expandIntent =
        releaseVelocity < -_releaseVelocityBiasThreshold ||
        netDragDy < -_netDragBiasThreshold;

    if (collapseIntent && expandIntent) {
      if (releaseVelocity.abs() > _releaseVelocityBiasThreshold) {
        collapseIntent = releaseVelocity > 0;
        expandIntent = releaseVelocity < 0;
      } else {
        collapseIntent = netDragDy > 0;
        expandIntent = netDragDy < 0;
      }
    }

    final double target;
    final String mode;
    if (collapseIntent && !expandIntent) {
      double collapseTarget = sorted.first;
      for (final double snap in sorted) {
        if (snap <= size - _peekEpsilon) {
          collapseTarget = snap;
        }
      }
      target = collapseTarget;
      mode = 'collapseIntent';
    } else if (expandIntent && !collapseIntent) {
      double expandTarget = sorted.last;
      for (final double snap in sorted) {
        if (snap >= size + _peekEpsilon) {
          expandTarget = snap;
          break;
        }
      }
      target = expandTarget;
      mode = 'expandIntent';
    } else {
      target = _nearestSnap(size, sorted);
      mode = 'nearest';
    }

    QuranPlayerDebugLog.log(
      'queue.snapAfterRelease',
      <String, Object?>{
        'from': size.toStringAsFixed(3),
        'to': target.toStringAsFixed(3),
        'mode': mode,
        'velocity': releaseVelocity.toStringAsFixed(1),
        'netDragDy': netDragDy.toStringAsFixed(1),
      },
    );

    if ((target - size).abs() < _peekEpsilon) {
      return;
    }

    controller.animateTo(
      target,
      duration: animationDuration,
      curve: animationCurve,
    );
  }

  static double _nearestSnap(double size, List<double> sorted) {
    double nearest = sorted.first;
    double minDistance = (size - nearest).abs();
    for (final double snap in sorted) {
      final double distance = (size - snap).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = snap;
      }
    }
    return nearest;
  }

  static void toggleMinMax({
    required DraggableScrollableController controller,
    required List<double> snapSizes,
  }) {
    if (!controller.isAttached || snapSizes.length < 2) {
      return;
    }
    final double minSize = snapSizes.reduce(
      (double a, double b) => a < b ? a : b,
    );
    final double maxSize = snapSizes.reduce(
      (double a, double b) => a > b ? a : b,
    );
    final double midpoint = (minSize + maxSize) / 2;
    final double target = controller.size >= midpoint ? minSize : maxSize;
    QuranPlayerDebugLog.log(
      'queue.toggleMinMax',
      <String, Object?>{
        'from': controller.size.toStringAsFixed(3),
        'to': target.toStringAsFixed(3),
      },
    );
    controller.animateTo(
      target,
      duration: animationDuration,
      curve: animationCurve,
    );
  }

  static void applyDragDelta({
    required DraggableScrollableController controller,
    required double sheetParentHeight,
    required List<double> snapSizes,
    required double deltaDy,
  }) {
    if (!controller.isAttached || sheetParentHeight <= 0 || snapSizes.isEmpty) {
      return;
    }
    final double minSize = snapSizes.reduce(
      (double a, double b) => a < b ? a : b,
    );
    final double maxSize = snapSizes.reduce(
      (double a, double b) => a > b ? a : b,
    );
    final double nextSize = (controller.size - deltaDy / sheetParentHeight)
        .clamp(minSize, maxSize);
    controller.jumpTo(nextSize);
  }
}

/// Label under the queue handle when the sheet is at peek height.
class _QueueSheetExpandHint extends StatelessWidget {
  const _QueueSheetExpandHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Semantics(
      identifier: QuranPlayerSemanticsIds.queueSheetExpandHint,
      label: context.l10n.playerQueueExpandHint,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceExtraSmall),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceTiny,
            children: [
              Icon(
                FluentIcons.chevron_up_24_regular,
                size: tokens.iconSizeSmall,
                color: color,
              ),
              Text(
                context.l10n.playerQueueExpandHint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drag handle that resizes the queue [DraggableScrollableSheet] between snap
/// points (peek ↔ full) instead of only scrolling the list.
class _PlayerQueueSheetHandle extends StatelessWidget {
  const _PlayerQueueSheetHandle({
    required this.controller,
    required this.sheetParentHeight,
    required this.snapSizes,
    required this.color,
    required this.showExpandHint,
    this.onCollapseToPeek,
    required this.onHandleTap,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
  });

  final DraggableScrollableController controller;
  final double sheetParentHeight;
  final List<double> snapSizes;
  final Color color;
  final bool showExpandHint;
  final VoidCallback? onCollapseToPeek;
  final VoidCallback onHandleTap;
  final VoidCallback onHandleDragStart;
  final void Function(
    double deltaDy, {
    required double sheetParentHeight,
    required List<double> snapSizes,
  })
  onHandleDragUpdate;
  final ValueChanged<DragEndDetails> onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: QuranPlayerSemanticsIds.queueSheetHandle,
      button: true,
      label: context.l10n.playerQueueHandleSemanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onHandleTap,
        onVerticalDragStart: (_) {
          onHandleDragStart();
          QuranPlayerDebugLog.log(
            'queue.handleDragStart',
            <String, Object?>{
              'size': controller.isAttached
                  ? controller.size.toStringAsFixed(3)
                  : null,
            },
          );
        },
        onVerticalDragUpdate: (DragUpdateDetails details) {
          onHandleDragUpdate(
            details.delta.dy,
            sheetParentHeight: sheetParentHeight,
            snapSizes: snapSizes,
          );
        },
        onVerticalDragEnd: (DragEndDetails details) {
          QuranPlayerDebugLog.log(
            'queue.handleDragEnd',
            <String, Object?>{
              'velocity': (details.primaryVelocity ?? 0).toStringAsFixed(1),
              'size': controller.isAttached
                  ? controller.size.toStringAsFixed(3)
                  : null,
            },
          );
          onHandleDragEnd(details);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TilawaSheetHandle(
              color: color,
              enableDragToDismiss: false,
              semanticLabel: context.l10n.playerQueueHandleSemanticLabel,
            ),
            if (showExpandHint) _QueueSheetExpandHint(color: color),
          ],
        ),
      ),
    );
  }
}

class _PlayerQueueSheet extends StatelessWidget {
  const _PlayerQueueSheet({
    required this.scrollController,
    required this.queueController,
    required this.sheetParentHeight,
    required this.peekSize,
    required this.snapSizes,
    required this.state,
    required this.currentAudio,
    required this.onCollapseToPeek,
    required this.onHandleTap,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
  });

  final ScrollController scrollController;
  final DraggableScrollableController queueController;
  final double sheetParentHeight;
  final double peekSize;
  final List<double> snapSizes;
  final AudioPlayerState state;
  final AudioEntity currentAudio;
  final VoidCallback onCollapseToPeek;
  final VoidCallback onHandleTap;
  final VoidCallback onHandleDragStart;
  final void Function(
    double deltaDy, {
    required double sheetParentHeight,
    required List<double> snapSizes,
  })
  onHandleDragUpdate;
  final ValueChanged<DragEndDetails> onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final List<AudioEntity> queue =
        state.playbackState?.queue ?? <AudioEntity>[];
    final Map<String, int> queueIndexById =
        QuranPlayerQueueUtils.queueIndexById(queue);
    final int? currentIndex = state.playbackState?.currentIndex;
    final String sourceLabel =
        currentAudio.album ??
        currentAudio.artist ??
        context.l10n.unknownReciter;
    final Color queueSheetColor = quranPlayerQueueSheetColor(colorScheme);
    final bool atPeek = _QueueSheetSnap.isAtPeek(
      controller: queueController,
      peekSize: peekSize,
    );

    final BorderRadius sheetRadius = BorderRadius.vertical(
      top: Radius.circular(tokens.radiusExtraLarge),
    );

    final Widget queueHeader = Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.playingFrom,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            sourceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      identifier: QuranPlayerSemanticsIds.queueSheet,
      container: true,
      child: Material(
        color: queueSheetColor,
        elevation: tokens.spaceTiny,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: sheetRadius,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _PlayerQueueSheetHandle(
              controller: queueController,
              sheetParentHeight: sheetParentHeight,
              snapSizes: snapSizes,
              showExpandHint: atPeek,
              onCollapseToPeek: onCollapseToPeek,
              onHandleTap: onHandleTap,
              onHandleDragStart: onHandleDragStart,
              onHandleDragUpdate: onHandleDragUpdate,
              onHandleDragEnd: onHandleDragEnd,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: tokens.opacityEmphasis,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: atPeek
                        ? Semantics(
                            button: true,
                            label: context.l10n.playerQueueHandleSemanticLabel,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _QueueSheetSnap.toggleMinMax(
                                  controller: queueController,
                                  snapSizes: snapSizes,
                                ),
                                child: queueHeader,
                              ),
                            ),
                          )
                        : queueHeader,
                  ),
                  if (queue.length > 1)
                    SliverReorderableList(
                      findChildIndexCallback: (Key key) =>
                          QuranPlayerQueueUtils.findReorderableChildIndex(
                            indexById: queueIndexById,
                            key: key,
                          ),
                      itemBuilder: (context, index) {
                        final AudioEntity item = queue[index];
                        final bool isCurrent = currentIndex == index;
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey<String>(item.id),
                          index: index,
                          child: Semantics(
                            identifier: QuranPlayerSemanticsIds.queueItem(
                              item.id,
                            ),
                            button: true,
                            child: _QueueTrackTile(
                              audio: item,
                              isCurrent: isCurrent,
                              isPlaying: isCurrent && state.isPlaying,
                              subtitle:
                                  item.artist != null &&
                                      item.artist != sourceLabel
                                  ? item.artist
                                  : null,
                              onTap: () {
                                if (!isCurrent) {
                                  context.read<AudioPlayerBloc>().add(
                                    AudioPlayerEvent.skipToQueueItem(index),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      itemCount: queue.length,
                      onReorderItem: (int oldIndex, int newIndex) {
                        context.read<AudioPlayerBloc>().add(
                          AudioPlayerEvent.moveQueueItem(oldIndex, newIndex),
                        );
                      },
                    )
                  else
                    SliverToBoxAdapter(
                      child: SizedBox(height: tokens.spaceExtraLarge),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom:
                          tokens.spaceLarge +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTrackTile extends StatelessWidget {
  const _QueueTrackTile({
    required this.audio,
    required this.isCurrent,
    required this.isPlaying,
    this.subtitle,
    required this.onTap,
  });

  final AudioEntity audio;
  final bool isCurrent;
  final bool isPlaying;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    return Material(
      color: isCurrent
          ? colorScheme.secondaryContainer.withValues(alpha: 0.55)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _MiniArtwork(artUri: audio.artUri, size: 48),
                  if (isCurrent && isPlaying)
                    Icon(
                      Icons.equalizer,
                      color: colorScheme.primary,
                      size: tokens.iconSizeMedium,
                    ),
                ],
              ),
              SizedBox(width: tokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spaceExtraSmall,
                  children: [
                    Text(
                      audio.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isCurrent
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.drag_handle,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedProgressBar extends StatelessWidget {
  const _ExpandedProgressBar();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, PositionData>(
      selector: (state) =>
          state.positionData ??
          const PositionData(
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
          ),
      builder: (context, positionData) {
        final theme = Theme.of(context);
        final tokens = theme.tokens;
        final palette = _ExpandedPlayerPalette.of(context);
        final seekActiveColor = palette.seekActive;
        final seekThumbColor = palette.seekActive;
        final seekBufferedColor = palette.seekBuffered;
        final seekInactiveColor = palette.seekInactive;
        final PlayerProgressTimes times = resolvePlayerProgressTimes(
          positionData,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          child: Column(
            spacing: tokens.spaceExtraSmall,
            children: [
              Semantics(
                identifier: QuranPlayerSemanticsIds.progressSeekBar,
                slider: true,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 0,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: TilawaSeekBar(
                    duration: positionData.duration,
                    position: times.elapsed,
                    bufferedPosition: positionData.bufferedPosition,
                    activeColor: seekActiveColor,
                    thumbColor: seekThumbColor,
                    bufferedColor: seekBufferedColor,
                    inactiveColor: seekInactiveColor,
                    onChangeEnd: (newPosition) {
                      context.read<AudioPlayerBloc>().add(
                        AudioPlayerEvent.seekTo(newPosition),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    identifier: QuranPlayerSemanticsIds.progressPosition,
                    child: Text(
                      formatPlayerDuration(times.elapsed),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.secondary,
                      ),
                    ),
                  ),
                  Semantics(
                    identifier: QuranPlayerSemanticsIds.progressDuration,
                    child: Text(
                      times.remainingLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen expanded player presented via [QuranPlayerExpandedRoute].
class QuranPlayerExpandedPageContent extends StatelessWidget {
  const QuranPlayerExpandedPageContent({
    required this.expandAnimation,
    required this.onCollapse,
    required this.onDismiss,
    required this.onExpandDragStart,
    required this.onExpandDragUpdate,
    required this.onExpandDragEnd,
  });

  final Animation<double> expandAnimation;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final VoidCallback onExpandDragStart;
  final ValueChanged<double> onExpandDragUpdate;
  final ValueChanged<DragEndDetails> onExpandDragEnd;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure,
      listener: (context, state) {
        final String? message = state.failure?.localizedMessage(context);
        if (message != null) {
          ToastUtils.showErrorToast(message);
        }
      },
      buildWhen: QuranPlayerTransportControls.playerTreeBuildWhen,
      builder: (context, state) {
        final AudioEntity? current = state.currentAudio;
        if (current == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            getIt<PlayerPresentationController>().onRouteClosed();
            if (context.canPop()) {
              context.pop();
            }
          });
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: expandAnimation,
          builder: (context, child) {
            final PlayerExpandTransitionMetrics metrics =
                PlayerExpandTransitionMetrics.compute(
                  progress: expandAnimation.value,
                  miniPlayerHeight: 0,
                );
            return PlayerExpandMetricsScope(
              metrics: metrics,
              child: child!,
            );
          },
          child: _ExpandedPlayerOrganism(
            state: state,
            audio: current,
            expandAnimation: expandAnimation,
            useHeroArtwork: true,
            onCollapse: onCollapse,
            onDismiss: onDismiss,
            onPlayerExpandDragStart: onExpandDragStart,
            onPlayerExpandDragUpdate: onExpandDragUpdate,
            onPlayerExpandDragEnd: onExpandDragEnd,
          ),
        );
      },
    );
  }
}
