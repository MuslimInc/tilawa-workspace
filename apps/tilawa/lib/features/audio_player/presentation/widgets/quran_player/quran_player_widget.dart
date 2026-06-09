/// Quran player UI — shell host, expanded stage, mini bar, and queue.
///
/// Split across [part] files for SRP and testability; import via
/// `package:tilawa/features/audio_player/presentation/widgets/quran_player/quran_player_widget.dart`
/// or the legacy `package:tilawa/shared/widgets/quran_player_widget.dart` export.
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/gestures.dart';
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
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_phase.dart';
import 'package:tilawa/features/audio_player/presentation/player_shell_overlay_host.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_presentation_entry.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/background_source_dialog.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/player_background_layer.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/get_history_by_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_history_section.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/helpers/show_slider_dialog.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_debug_log.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_gesture_policy.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_stage_gesture_scope.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_stage_layouts.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_hero.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layer.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa/shared/widgets/quran_player_progress_display.dart';
import 'package:tilawa/shared/widgets/quran_player_queue_utils.dart';
import 'package:tilawa/shared/widgets/quran_player_system_back.dart';
import 'package:tilawa/shared/widgets/quran_player_transport_controls.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

part 'quran_player_organisms.dart';
part 'quran_player_controls.dart';
part 'quran_player_mini.dart';
part 'quran_player_queue.dart';
part 'quran_player_route_page.dart';

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
    this.hostAbsorbsBottomSafeArea = false,
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
        return QuranPlayerLayoutInsets.phoneFooterSlotHeight(
              context,
              playerHeight: collapsedHeight(context),
              hostAbsorbsBottomSafeArea: shell.hostAbsorbsBottomSafeArea,
            ) +
            shell.bottomNavBarHeight;
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
      // Phone shell: mini player lives in [Scaffold.bottomNavigationBar] below
      // this route's scaffold, so only a standard FAB margin is needed.
      if (shell != null && context.isNarrow) {
        return context.tokens.spaceSmall;
      }
    }

    return collapsedFootprint(context);
  }

  /// Height of the bottom navigation bar to offset the mini player.
  final double bottomNavBarHeight;

  /// Whether the keyboard is currently open.
  final bool isKeyboardOpen;

  /// When true with [bottomNavBarHeight] == 0, the mini player anchors flush
  /// to the layout bottom (no [floatingBottomPadding]) because the host already
  /// stacks bottom chrome (e.g. phone-layout shell [BottomNavigationBar]) that
  /// includes the system gesture inset.
  final bool hostAbsorbsBottomSafeArea;

  @override
  State<QuranPlayerWidget> createState() => QuranPlayerWidgetState();
}

class QuranPlayerWidgetState extends State<QuranPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  final OverlayPortalController _portalController = OverlayPortalController();
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

  /// Frozen at [drag.start] so overlay layout cannot retune travel mid-gesture.
  double? _expandDragFrozenAnchorHeight;

  /// Routes all pointer moves to [_applyExpandDragPixels] while the shell
  /// footer drag is active. The overlay portal paints above the footer mini,
  /// so the footer [GestureDetector] often stops receiving updates after the
  /// first frame even though the arena was won at pointer-down.
  bool _shellExpandPointerRouteAttached = false;
  PointerRoute? _shellExpandPointerRoute;
  bool _expandDragEndHandled = false;
  int? _expandDragActivePointerId;

  bool _idleShellSettleScheduled = false;

  /// Coalesced target for [_syncShellPortalVisibility] (applied post-frame
  /// when the scheduler is in [SchedulerPhase.persistentCallbacks]).
  bool _pendingPortalVisible = false;
  bool _shellPortalVisibilitySyncScheduled = false;

  /// Controls the swipe-down-to-dismiss offset for the mini player.
  double _dismissOffsetY = 0;
  Animation<double>? _dismissAnimation;
  late AnimationController _dismissAnimController;

  late final PlayerShellOverlayHost _shellOverlayHost;

  /// Cached screen height minus the shell footer slot top in the overlay.
  ///
  /// Set each frame in the overlay builder so [_applyExpandDragPixels] can
  /// use the same anchor the sheet geometry uses. Falls back to
  /// [_miniPlayerHeight] until the first overlay layout.
  double _shellAnchorHeight = 0;

  /// The height of the mini player bar (excluding nav bar offset).
  /// Must be tall enough for: outer padding (8+16) + progress bar (3) +
  /// inner padding (12+12) + row content (~48) = ~99.
  double get _miniPlayerHeight => QuranPlayerWidget.collapsedHeight(context);

  /// Whether the player is currently expanded.
  bool get isExpanded => _presentation.isExpandedSettled;

  /// Whether the player is currently expanding or expanded.
  bool get isExpanding =>
      _presentation.visualProgress > 0.01 ||
      _expandController.isAnimating ||
      _isUserDraggingExpand;

  Map<String, Object?> _coreStateFields() {
    return <String, Object?>{
      ..._presentation.snapshot(),
      'expandProgress': _expandController.value.toStringAsFixed(3),
      'expandStatus': _expandController.status.name,
      'expandIsAnimating': _expandController.isAnimating,
      'dismissOffsetY': _dismissOffsetY.toStringAsFixed(1),
      'route': _currentRoutePath(),
      'portalShowing': _portalController.isShowing,
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

  @override
  void initState() {
    super.initState();
    QuranPlayerDebugLog.lifecycle('initState', const <String, Object?>{});
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
    _shellOverlayHost = _QuranPlayerShellOverlayHost(this);
    _expandController.addListener(_syncPlayerSystemChrome);
    _expandController.addListener(_syncSystemBackIntercepts);
    _expandController.addStatusListener(_onExpandAnimationStatus);
    _presentation.addListener(_onPresentationChanged);
    _presentation.bindShellOverlay(_shellOverlayHost);
    _expandController.addListener(_onShellExpandControllerTick);

    _systemBackHandle = handleSystemBack;
    _dismissHandle = _dismissWithUndo;
    _presentation.bindSystemBack(handle: _systemBackHandle);
    _presentation.bindDismissPlayer(handle: _dismissHandle);
    _logAnimationControllers('initState.controllersReady');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        QuranPlayerDebugLog.lifecycle('firstFrame', _coreStateFields());
        _syncPlayerSystemChrome();
        _settleIdleShellOverlayIfNeeded(reason: 'firstFrame');
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
      _presentation.reconcileWithNavigationStack();
    }
  }

  @override
  void didUpdateWidget(covariant QuranPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottomNavBarHeight != widget.bottomNavBarHeight ||
        oldWidget.isKeyboardOpen != widget.isKeyboardOpen ||
        oldWidget.hostAbsorbsBottomSafeArea !=
            widget.hostAbsorbsBottomSafeArea) {
      QuranPlayerDebugLog.lifecycle(
        'didUpdateWidget',
        <String, Object?>{
          ..._coreStateFields(),
          'keyboardOpen': widget.isKeyboardOpen,
          'bottomNavBarHeight': widget.bottomNavBarHeight,
        },
      );
      _syncPlayerSystemChrome();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _settleIdleShellOverlayIfNeeded(reason: 'reassemble');
    });
  }

  @override
  void deactivate() {
    QuranPlayerDebugLog.lifecycle('deactivate', _coreStateFields());
    _detachShellExpandPointerRoute();
    _isUserDraggingExpand = false;
    _expandDragNetDy = 0;
    _expandDragFrozenAnchorHeight = null;
    _expandDragActivePointerId = null;
    if (_expandController.isAnimating) {
      _expandController.stop();
    }
    final double progress = _expandController.value;
    if (progress > 0.01 && progress < 0.99) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _snapShellOverlayIdleProgress(immediate: true);
      });
    }
    QuranPlayerSystemBackCoordinator.unbind(handle: _systemBackHandle);
    context
        .read<QuranPlayerChromeNotifier>()
        .clearSystemNavigationBarColorOverride();
    super.deactivate();
  }

  @override
  void dispose() {
    QuranPlayerDebugLog.lifecycle('dispose', _coreStateFields());
    _detachShellExpandPointerRoute();
    _presentation.unbindDismissPlayer(handle: _dismissHandle);
    _presentation.unbindSystemBack(handle: _systemBackHandle);
    _presentation.unbindShellOverlay(_shellOverlayHost);
    _expandController.removeListener(_onShellExpandControllerTick);
    _hideShellPortalSafely();
    _presentation.removeListener(_onPresentationChanged);
    QuranPlayerSystemBackCoordinator.unbind(handle: _systemBackHandle);
    _expandController.removeStatusListener(_onExpandAnimationStatus);
    _expandController.removeListener(_syncPlayerSystemChrome);
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
        isExpanding;
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
      _isCollapsing =
          _presentation.phase == PlayerPresentationPhase.collapsing ||
          _presentation.collapseBiasedForMetrics;
      if (_presentation.phase == PlayerPresentationPhase.mini) {
        _isCollapsing = false;
      }
      if (_presentation.routeOpen &&
          _expandController.value > 0.01 &&
          !_expandController.isAnimating &&
          !_isUserDraggingExpand) {
        unawaited(_collapseShellOverlay());
      } else if (!_presentation.routeOpen &&
          _presentation.phase == PlayerPresentationPhase.mini &&
          _expandController.value > 0.01 &&
          !_expandController.isAnimating &&
          !_isUserDraggingExpand) {
        _expandController.value = 0;
        _syncShellOverlayPresentation();
      }
      _syncShellPortalVisibility();
      _syncPlayerSystemChrome();
      _syncSystemBackIntercepts();
    });
  }

  void _onShellExpandControllerTick() {
    _syncShellPortalVisibility();
    _syncShellOverlayPresentation();
  }

  void _syncShellOverlayPresentation() {
    if (!_presentation.hasShellOverlayHost) {
      _presentation.bindShellOverlay(_shellOverlayHost);
    }
    _presentation.syncShellOverlayProgress(
      progress: _expandController.value,
      status: _expandController.status,
      isCollapsing: _isCollapsing,
      isUserDragging: _isUserDraggingExpand,
    );
  }

  /// Keeps [PlayerPresentationController] aligned with [_expandController].
  void _reconcileShellPresentationWithController() {
    if (!mounted) {
      return;
    }
    final double controllerProgress = _expandController.value;
    if ((_presentation.transitionProgress - controllerProgress).abs() <=
        0.015) {
      return;
    }
    QuranPlayerDebugLog.warn(
      'shell.presentationDesync',
      <String, Object?>{
        'controller': controllerProgress.toStringAsFixed(3),
        'presentation': _presentation.transitionProgress.toStringAsFixed(3),
        'phase': _presentation.phase.name,
      },
    );
    _syncShellOverlayPresentation();
  }

  void _scheduleIdleShellOverlaySettleIfNeeded() {
    if (_idleShellSettleScheduled) {
      return;
    }
    _idleShellSettleScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _idleShellSettleScheduled = false;
      if (!mounted) {
        return;
      }
      _reconcileShellPresentationWithController();
      if (_expandController.isAnimating || _isUserDraggingExpand) {
        return;
      }
      final double progress = _expandController.value;
      if (progress > 0.02 && progress < 0.98) {
        _settleIdleShellOverlayIfNeeded(reason: 'idleMidProgress');
      }
    });
  }

  /// OverlayPortal paints **above** its [child]. When collapsed, the portal
  /// must be hidden or the mini bar is covered (list shows through).
  void _syncShellPortalVisibility() {
    final bool wantOverlay =
        _expandController.value > 0.01 ||
        _expandController.isAnimating ||
        _isUserDraggingExpand;
    if (wantOverlay == _pendingPortalVisible &&
        _shellPortalVisibilitySyncScheduled) {
      return;
    }
    _pendingPortalVisible = wantOverlay;
    _scheduleShellPortalVisibilitySync();
  }

  void _scheduleShellPortalVisibilitySync() {
    if (_shellPortalVisibilitySyncScheduled) {
      return;
    }
    _shellPortalVisibilitySyncScheduled = true;
    void apply() {
      _shellPortalVisibilitySyncScheduled = false;
      if (!mounted) {
        return;
      }
      final bool show = _pendingPortalVisible;
      if (show) {
        if (!_portalController.isShowing) {
          _portalController.show();
        }
      } else if (_portalController.isShowing) {
        _portalController.hide();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  void _hideShellPortalSafely() {
    _pendingPortalVisible = false;
    if (!_portalController.isShowing) {
      return;
    }
    void hide() {
      if (_portalController.isShowing) {
        _portalController.hide();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => hide());
      return;
    }
    hide();
  }

  bool get _shellOverlayPortalActive =>
      _expandController.value > 0.01 ||
      _expandController.isAnimating ||
      _isUserDraggingExpand;

  /// Snaps an idle, interrupted shell transition to mini or expanded.
  ///
  /// When [collapseBiased] is true at mid-progress, opacity curves keep the
  /// mini nearly invisible until progress reaches ~0.22 — snap to mini.
  void _snapShellOverlayIdleProgress({required bool immediate}) {
    if (!mounted) {
      return;
    }
    final double progress = _expandController.value;
    if (progress <= 0.01) {
      _isCollapsing = false;
      _syncShellOverlayPresentation();
      _syncShellPortalVisibility();
      return;
    }
    if (progress >= 0.99) {
      _isCollapsing = false;
      _syncShellOverlayPresentation();
      _syncShellPortalVisibility();
      return;
    }

    final bool collapseStuck =
        _isCollapsing ||
        _presentation.collapseBiasedForMetrics ||
        _presentation.phase == PlayerPresentationPhase.collapsing;
    final double threshold = context.tokens.playerProgressThreshold;
    final double target = collapseStuck
        ? 0.0
        : (progress < threshold ? 0.0 : 1.0);

    _isCollapsing = target == 0.0;

    QuranPlayerDebugLog.animation(
      'shell.snap.idle',
      <String, Object?>{
        'from': progress.toStringAsFixed(3),
        'target': target.toStringAsFixed(0),
        'collapseStuck': collapseStuck,
        'immediate': immediate,
        ..._coreStateFields(),
      },
    );

    if (immediate) {
      _expandController.removeListener(_onShellExpandControllerTick);
      _expandController.value = target;
      _expandController.addListener(_onShellExpandControllerTick);
      _onShellExpandControllerTick();
    } else {
      unawaited(
        _expandController.animateTo(
          target,
          duration: context.tokens.durationMedium,
          curve: Curves.easeOutCubic,
        ),
      );
    }
    _syncShellPortalVisibility();
  }

  void _settleIdleShellOverlayIfNeeded({required String reason}) {
    if (!mounted) {
      return;
    }
    if (_expandController.isAnimating || _isUserDraggingExpand) {
      _syncShellPortalVisibility();
      return;
    }
    final double progress = _expandController.value;
    if (progress <= 0.02 || progress >= 0.98) {
      if (progress <= 0.02 && progress > 0) {
        _expandController.value = 0;
      }
      _isCollapsing = false;
      _syncShellOverlayPresentation();
      _syncShellPortalVisibility();
      return;
    }
    QuranPlayerDebugLog.animation(
      'shell.settle.$reason',
      <String, Object?>{
        'from': progress.toStringAsFixed(3),
        ..._coreStateFields(),
      },
    );
    _snapShellOverlayIdleProgress(immediate: true);
  }

  /// Publishes player-owned system navigation colors app-wide.
  void _syncPlayerSystemChrome() {
    if (!mounted) {
      return;
    }
    final QuranPlayerChromeNotifier notifier = context
        .read<QuranPlayerChromeNotifier>();
    final bool overlayActive =
        _presentation.overlayChromeActive && _portalController.isShowing;
    if (overlayActive) {
      notifier.setSystemNavigationBarColorOverride(
        quranPlayerQueueSheetColor(Theme.of(context).colorScheme),
      );
    } else if (!widget.hostAbsorbsBottomSafeArea &&
        widget.bottomNavBarHeight == 0) {
      notifier.setSystemNavigationBarColorOverride(
        Theme.of(context).componentTokens.mediaPlayerBar.shellBackgroundColor,
      );
    } else {
      notifier.clearSystemNavigationBarColorOverride();
    }
  }

  /// Expand the player to full-screen.
  ///
  /// Shell footer: in-place overlay via [PlayerPresentationController].
  void expand() {
    HapticFeedback.lightImpact();
    _isCollapsing = false;
    unawaited(
      QuranPlayerPresentationEntry.openExpanded(
        presentation: _presentation,
        hasActiveAudio: _audioBloc.state.hasAudio,
      ),
    );
  }

  Future<void> _expandShellOverlay() async {
    _isCollapsing = false;
    _syncShellPortalVisibility();
    await _expandController.animateTo(
      1.0,
      duration: context.tokens.durationMedium,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _collapseShellOverlay() async {
    _isCollapsing = true;
    _syncShellPortalVisibility();
    await _expandController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      _isCollapsing = false;
      _syncShellPortalVisibility();
    }
  }

  /// Collapse the player back to the mini bar.
  void collapse() {
    _isCollapsing = true;
    QuranPlayerDebugLog.animation(
      'collapse.start',
      <String, Object?>{
        'from': _expandController.value.toStringAsFixed(3),
        ..._coreStateFields(),
      },
    );
    _presentation.collapse();
  }

  /// Phone shell: animate sheet + mini in one overlay layer to avoid desync.
  /// True when the sheet must render in the overlay layer (above the shell
  /// scaffold) rather than in the footer slot. This is required both during
  /// programmatic animations AND during user drag — otherwise the expanding
  /// sheet renders inside the footer slot and the page content paints on top.
  bool get _animateShellInOverlay {
    final double progress = _expandController.value;
    return _expandController.isAnimating ||
        _isUserDraggingExpand ||
        (_portalController.isShowing && progress > 0.01 && progress < 0.99);
  }

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
      if (_expandController.value <= 0.01) {
        _isCollapsing = false;
      }
      if (_expandController.value >= 0.99) {
        _isCollapsing = false;
      }
      _settleIdleShellOverlayIfNeeded(reason: 'animationStatus');
    }
  }

  bool _phoneBottomNavVisibleForLayout() {
    return AppShellRoutePolicy.isPhoneBottomNavigationVisible(
      _currentRoutePath(),
    );
  }

  bool _collapseBiasedMetrics(double progress) {
    if (_isCollapsing) {
      return true;
    }
    if (_isUserDraggingExpand && progress < _expandDragStartProgress - 0.001) {
      return true;
    }
    return false;
  }

  PlayerExpandTransitionMetrics _transitionMetrics(
    double progress, {
    bool footerHandoff = false,
  }) {
    final bool collapseBiased = _isUserDraggingExpand
        ? _collapseBiasedMetrics(progress)
        : _presentation.collapseBiasedForMetrics;
    return PlayerExpandTransitionMetrics.compute(
      progress: progress,
      miniPlayerHeight: _miniPlayerHeight,
      interactiveDrag: _isUserDraggingExpand,
      collapseBiased: collapseBiased,
      interactiveCollapseAnchor: _isUserDraggingExpand && collapseBiased
          ? _expandDragStartProgress
          : null,
      heroHandoff: footerHandoff && _presentation.routeOpen,
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
    required double miniPlayerHeight,
  }) {
    final double t = metrics.sheetMotionT.clamp(0.0, 1.0);
    final double sheetHeight =
        miniPlayerHeight + (screenHeight - miniPlayerHeight) * t;
    return screenHeight - sheetHeight;
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
    if (!metrics.showMorphLayer) {
      return null;
    }
    // Hero artwork uses [Hero] while `/player` is open; morph handles the
    // footer handoff after the route leaves the stack.
    if (_presentation.routeOpen) {
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
    final double morphAnchor = _shellAnchorHeight > 0
        ? _shellAnchorHeight
        : _miniPlayerHeight;
    final layout = QuranPlayerMorphLayout.compute(
      progress: progress,
      viewport: overlaySize,
      miniBarRect: miniBarRect,
      sheetOffsetY: _sheetTravelOffset(
        metrics: metrics,
        screenHeight: overlaySize.height,
        miniPlayerHeight: morphAnchor,
      ),
      geometry: geometry,
      textDirection: Directionality.of(context),
    );
    return QuranPlayerMorphLayer(
      audio: audio,
      handoffT: metrics.handoffT,
      layout: layout,
      onImageBackdrop: false,
    );
  }

  void _attachShellExpandPointerRoute() {
    if (_shellExpandPointerRouteAttached) {
      return;
    }
    _shellExpandPointerRoute ??= _handleShellExpandPointerEvent;
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _shellExpandPointerRoute!,
    );
    _shellExpandPointerRouteAttached = true;
  }

  void _detachShellExpandPointerRoute() {
    if (!_shellExpandPointerRouteAttached || _shellExpandPointerRoute == null) {
      return;
    }
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _shellExpandPointerRoute!,
    );
    _shellExpandPointerRouteAttached = false;
  }

  void _handleShellExpandPointerEvent(PointerEvent event) {
    if (!_isUserDraggingExpand) {
      return;
    }
    if (event is PointerMoveEvent) {
      if (!QuranPlayerExpandGesturePolicy.shouldPointerRouteApplyMove(
        isUserDraggingExpand: _isUserDraggingExpand,
        activePointerId: _expandDragActivePointerId,
        eventPointerId: event.pointer,
      )) {
        return;
      }
      _expandDragActivePointerId ??= event.pointer;
      _applyExpandDragPixels(
        event.delta.dy,
        source: 'pointerRoute',
        channel: QuranPlayerExpandDragChannel.pointerRoute,
      );
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (!QuranPlayerExpandGesturePolicy.shouldPointerRouteFinishOnRelease(
        pointerRouteAttached: _shellExpandPointerRouteAttached,
        dragEndHandled: _expandDragEndHandled,
        activePointerId: _expandDragActivePointerId,
        eventPointerId: event.pointer,
      )) {
        return;
      }
      _finishExpandDrag(
        DragEndDetails(primaryVelocity: 0),
        source: 'pointerRoute',
      );
    }
  }

  void _onExpandGestureStart() {
    _expandDragEndHandled = false;
    _expandDragActivePointerId = null;
    _isUserDraggingExpand = true;
    _expandDragStartProgress = _expandController.value;
    _expandDragNetDy = 0;
    // canceled: true would emit [AnimationStatus.dismissed] and
    // [_onExpandAnimationStatus] used to clear [_isUserDraggingExpand] here,
    // orphaning the footer drag after the first pixel.
    _expandController.stop(canceled: false);
    _isCollapsing = false;
    _seedShellAnchorForExpandDrag();
    _expandDragFrozenAnchorHeight = _shellAnchorHeight;
    _presentation.syncShellOverlayProgress(
      progress: _expandController.value,
      status: _expandController.status,
      isCollapsing: _isCollapsing,
      isUserDragging: true,
    );
    _pendingPortalVisible = true;
    if (!_portalController.isShowing) {
      _portalController.show();
    }
    _attachShellExpandPointerRoute();
    QuranPlayerDebugLog.drag(
      'expandGesture.start',
      <String, Object?>{
        ..._coreStateFields(),
        'expandWasAnimating': _expandController.isAnimating,
      },
    );
    setState(() {});
  }

  /// Pre-seeds [_shellAnchorHeight] before the overlay's first layout so drag
  /// travel matches YouTube Music 1:1 tracking from the first pixel.
  void _seedShellAnchorForExpandDrag() {
    if (!mounted) {
      return;
    }
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double footprint = QuranPlayerWidget.collapsedFootprint(
      context,
      bottomNavBarHeight: widget.bottomNavBarHeight,
      hostAbsorbsBottomSafeArea: widget.hostAbsorbsBottomSafeArea,
    );
    final double anchorTop = (screenHeight - footprint).clamp(
      0.0,
      screenHeight - _miniPlayerHeight,
    );
    _shellAnchorHeight = (screenHeight - anchorTop).clamp(
      _miniPlayerHeight,
      screenHeight,
    );
    if (_isUserDraggingExpand) {
      _expandDragFrozenAnchorHeight = _shellAnchorHeight;
    }
  }

  void _applyExpandDragPixels(
    double dragPixels, {
    required String source,
    QuranPlayerExpandDragChannel channel =
        QuranPlayerExpandDragChannel.footerRecognizer,
  }) {
    if (!mounted) {
      QuranPlayerDebugLog.warn(
        'drag.update.unmounted',
        <String, Object?>{'source': source},
      );
      return;
    }
    if (!QuranPlayerExpandGesturePolicy.shouldApplyRecognizerDragDelta(
      pointerRouteAttached: _shellExpandPointerRouteAttached,
      channel: channel,
    )) {
      return;
    }
    // Travel = screen height minus anchor height so the sheet top tracks the
    // finger 1:1 (YouTube Music style). _shellAnchorHeight (= screenH -
    // hostRect.top) is set each overlay frame; seeded at drag start before
    // the portal's first layout.
    final double anchor =
        _isUserDraggingExpand && _expandDragFrozenAnchorHeight != null
        ? _expandDragFrozenAnchorHeight!
        : _shellAnchorHeight > 0
        ? _shellAnchorHeight
        : _miniPlayerHeight;
    final double travel = (context.viewportHeight - anchor).clamp(
      1.0,
      double.infinity,
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
  }

  void _finishExpandDrag(DragEndDetails details, {required String source}) {
    if (_expandDragEndHandled) {
      return;
    }
    _expandDragEndHandled = true;
    _detachShellExpandPointerRoute();
    _isUserDraggingExpand = false;
    _expandDragFrozenAnchorHeight = null;
    _expandDragActivePointerId = null;
    _syncShellOverlayPresentation();
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
      _isCollapsing = false;
      if (progress < 0.98) {
        // Shell footer: animate directly so there is no async gap between
        // _isUserDraggingExpand=false and the animation starting. If we go
        // through expand() → PresentationEntry.openExpanded() the async await
        // leaves _animateShellInOverlay=false for one frame, freezing the UI.
        unawaited(_expandShellOverlay());
      } else if (progress < 0.999) {
        _expandController.value = 1;
        _syncShellOverlayPresentation();
        _syncShellPortalVisibility();
      }
    } else {
      if (progress > 0.08) {
        // Same reasoning: animate directly for shell footer to avoid gap.
        _isCollapsing = true;
        unawaited(_collapseShellOverlay());
      } else {
        _expandController.value = 0;
        _isCollapsing = false;
        _syncShellOverlayPresentation();
        _syncShellPortalVisibility();
      }
    }
  }

  /// Bottom inset for the floating mini player while [progress] is animating.
  double _miniPlayerBottomInsetForProgress(
    BuildContext context,
    double progress,
  ) {
    final String location = _currentRoutePath();
    return QuranPlayerLayoutInsets.miniPlayerBottomInset(
      context: context,
      hostBottomNavBarHeight: widget.bottomNavBarHeight,
      hostAbsorbsBottomSafeArea: widget.hostAbsorbsBottomSafeArea,
      phoneNavVisible: _phoneBottomNavVisibleForLayout(),
      routePath: location,
    );
  }

  /// Current route path without [GoRouterState.of] (overlay is above the router).
  static String _currentRoutePath() =>
      QuranPlayerRoutePolicy.currentMatchedLocation();

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
      return;
    }

    if (_expandController.value <= 0 && primaryDelta < 0) {
      _onExpandGestureStart();
    }
    _applyExpandDragPixels(
      primaryDelta,
      source: 'mini',
      channel: QuranPlayerExpandDragChannel.footerRecognizer,
    );
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
    if (isExpanding) {
      collapse();
    }
    context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.stopAudio());
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranPlayerWidget');

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portalController,
      overlayChildBuilder: _buildExpandedOverlay,
      child: _buildShellFooterMini(context),
    );
  }

  double _shellFooterBottomSpacing(BuildContext context) {
    return QuranPlayerLayoutInsets.phoneFooterBottomSpacing(
      context,
      hostAbsorbsBottomSafeArea: widget.hostAbsorbsBottomSafeArea,
    );
  }

  /// Mini player anchored in the shell footer column (YouTube Music style).
  Widget _buildShellFooterMini(BuildContext context) {
    final double bottomSpacing = _shellFooterBottomSpacing(context);
    final Color playerChromeColor = Theme.of(
      context,
    ).componentTokens.mediaPlayerBar.shellBackgroundColor;
    return ColoredBox(
      color: playerChromeColor,
      child: SizedBox(
        height: _miniPlayerHeight + bottomSpacing,
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(
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
            ),
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedOverlay(
    BuildContext overlayContext,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    if (!_shellOverlayPortalActive) {
      return const SizedBox.shrink();
    }

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
            onPlayerExpandDragUpdate: (double dy) => _applyExpandDragPixels(
              dy,
              source: 'expanded',
              channel: QuranPlayerExpandDragChannel.expandedRecognizer,
            ),
            onPlayerExpandDragEnd: (DragEndDetails details) =>
                _finishExpandDrag(details, source: 'expanded'),
          ),
        );

        final Widget? footerMiniGestureChild = miniAnchoredInFooter
            ? _MiniPlayerTransition(
                key: const ValueKey<String>('shell_footer_mini_gesture'),
                progress: 0,
                audio: audio,
                useHeroArtwork: false,
                identityChromeOpacity: 1,
                retainExpandDragGestures: true,
                dismissAnimController: _dismissAnimController,
                dismissAnimation: _dismissAnimation,
                dismissOffsetY: _dismissOffsetY,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onTap: expand,
                onClose: _dismissWithUndo,
              )
            : null;

        return AnimatedBuilder(
          animation: Listenable.merge(
            <Listenable>[
              _expandController,
              if (!_isUserDraggingExpand) _presentation,
            ],
          ),
          child: footerMiniGestureChild != null
              ? _PlayerAnimatedSubtree(
                  expandedPlayer: expandedPlayer,
                  footerMiniGesture: footerMiniGestureChild,
                )
              : expandedPlayer,
          builder: (context, animatedChild) {
            final Widget expandedChild;
            final Widget? stableFooterMini;
            if (animatedChild is _PlayerAnimatedSubtree) {
              expandedChild = animatedChild.expandedPlayer;
              stableFooterMini = animatedChild.footerMiniGesture;
            } else {
              expandedChild = animatedChild!;
              stableFooterMini = null;
            }

            // Sheet geometry must follow [_expandController] — not
            // [PlayerPresentationController.visualProgress], which can stay at
            // 1.0 while a drag pulls the controller back to ~0.8.
            final double layoutProgress = _expandController.value.clamp(
              0.0,
              1.0,
            );
            final PlayerExpandTransitionMetrics metrics = _transitionMetrics(
              layoutProgress,
            );
            if (!_isUserDraggingExpand) {
              _reconcileShellPresentationWithController();
              if (!_expandController.isAnimating) {
                _scheduleIdleShellOverlaySettleIfNeeded();
              }
            }
            final bool animateShellInOverlay = _animateShellInOverlay;
            final double layoutBottomInset = showMiniInTree
                ? _miniPlayerBottomInsetForProgress(context, layoutProgress)
                : 0;

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
              progress: layoutProgress,
              metrics: metrics,
              overlaySize: overlaySize,
              miniBarRect: miniBarRect,
              collapseAnchorY: hostRect.top,
            );

            final Widget miniPlayer = Opacity(
              opacity: metrics.miniOpacity,
              child: Transform.translate(
                offset: Offset(0, metrics.miniSlideY),
                child:
                    stableFooterMini ??
                    _MiniPlayerTransition(
                      progress: layoutProgress,
                      audio: audio,
                      useHeroArtwork: false,
                      identityChromeOpacity: metrics.miniIdentityOpacity,
                      retainExpandDragGestures: _isUserDraggingExpand,
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
              // Sheet anchor = full height from mini-bar top to screen bottom.
              // This ensures the sheet top starts flush with the mini bar and
              // tracks the finger 1:1 (YouTube Music style).
              final double anchorHeight = (screenHeight - hostRect.top).clamp(
                _miniPlayerHeight,
                screenHeight,
              );
              if (!_isUserDraggingExpand &&
                  _shellAnchorHeight != anchorHeight) {
                _shellAnchorHeight = anchorHeight;
              }
              return SizedBox(
                height: screenHeight,
                width: overlaySize.width,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (metrics.backdropOpacity > 0)
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
                    if (metrics.showExpandedSheet)
                      IgnorePointer(
                        // Overlay paints above the footer mini; the growing
                        // sheet must not steal the active vertical drag.
                        ignoring: _isUserDraggingExpand,
                        child: PlayerExpandMetricsScope(
                          metrics: metrics,
                          child: _ExpandedPlayerMotion(
                            sheetMotionT: metrics.sheetMotionT,
                            screenHeight: screenHeight,
                            miniPlayerHeight: anchorHeight,
                            sheetOpacity: metrics.sheetPresentationOpacity,
                            semanticLabel:
                                context.l10n.playerExpandedSheetSemanticLabel,
                            child: expandedChild,
                          ),
                        ),
                      ),
                    if (animateShellInOverlay && metrics.showMiniPlayer)
                      Positioned(
                        top: hostRect.top,
                        left: 0,
                        right: 0,
                        height: _miniPlayerHeight,
                        // During user drag the footer mini's GestureDetector
                        // owns the arena. This overlay copy is visual-only;
                        // if interactive it creates a second recognizer that
                        // reports conflicting deltas and reverses progress.
                        child: IgnorePointer(
                          ignoring: _isUserDraggingExpand,
                          child: miniPlayer,
                        ),
                      ),
                    if (morphLayer != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: _isUserDraggingExpand,
                          child: morphLayer,
                        ),
                      ),
                  ],
                ),
              );
            }

            if (miniAnchoredInFooter) {
              // The overlay covers this slot whenever the portal is active.
              // BUT: the footer mini's GestureDetector wins the gesture arena
              // at pointer-down time. Replacing it with SizedBox.shrink()
              // mid-gesture orphans the pointer — all Update/End events stop.
              // Solution: keep it alive at Opacity(0) during active drag so
              // the winning recognizer stays mounted and events keep flowing.
              if (_isUserDraggingExpand) {
                return SizedBox(
                  height: _miniPlayerHeight,
                  child: Opacity(opacity: 0, child: miniPlayer),
                );
              }
              if (_shellOverlayPortalActive) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: _miniPlayerHeight,
                child: IgnorePointer(
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
                      if (metrics.backdropOpacity > 0)
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
                      if (metrics.showExpandedSheet)
                        IgnorePointer(
                          ignoring: _isUserDraggingExpand,
                          child: PlayerExpandMetricsScope(
                            metrics: metrics,
                            child: _ExpandedPlayerMotion(
                              sheetMotionT: metrics.sheetMotionT,
                              screenHeight: screenHeight,
                              miniPlayerHeight: _miniPlayerHeight,
                              sheetOpacity: metrics.sheetPresentationOpacity,
                              semanticLabel:
                                  context.l10n.playerExpandedSheetSemanticLabel,
                              child: expandedChild,
                            ),
                          ),
                        ),
                      if (morphLayer != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _isUserDraggingExpand,
                            child: morphLayer,
                          ),
                        ),
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
