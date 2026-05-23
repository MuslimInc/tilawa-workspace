import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/audio_player/domain/entities/player_background_configuration.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../../features/audio_player/presentation/quran_player_semantics_ids.dart';
import '../../features/audio_player/presentation/widgets/background_source_dialog.dart';
import '../../features/audio_player/presentation/widgets/player_background_layer.dart';
import '../../features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../helpers/show_slider_dialog.dart';
import '../models/position_data.dart';
import 'quran_player_chrome.dart';
import 'quran_player_system_back.dart';
import 'quran_player_progress_display.dart';
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
  String? _lastSyncedRoutePath;
  late final void Function() _systemBackHandle;
  late AudioPlayerBloc _audioBloc;

  /// Set by [collapse] until the sheet settles at progress 0.
  ///
  /// [AnimationController.status] stays [AnimationStatus.forward] during
  /// [AnimationController.animateTo] toward 0 on some runtimes, so we cannot
  /// rely on [AnimationStatus.reverse] to detect collapse.
  bool _isCollapsing = false;

  /// Controls the swipe-down-to-dismiss offset for the mini player.
  double _dismissOffsetY = 0;
  Animation<double>? _dismissAnimation;
  late AnimationController _dismissAnimController;

  /// The height of the mini player bar (excluding nav bar offset).
  /// Must be tall enough for: outer padding (8+16) + progress bar (3) +
  /// inner padding (12+12) + row content (~48) = ~99.
  double get _miniPlayerHeight => QuranPlayerWidget.collapsedHeight(context);

  /// Whether the player is currently expanded.
  bool get isExpanded => _expandController.value == 1.0;

  /// Whether the player is currently expanding or expanded.
  bool get isExpanding => _expandController.value > 0.01;

  @override
  void initState() {
    super.initState();
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

    _expandController.addListener(_syncPhoneBottomNavBarVisible);
    _expandController.addListener(_syncExpandedPlayerSystemChrome);
    _expandController.addListener(_syncSystemBackIntercepts);
    _expandController.addStatusListener(_onExpandAnimationStatus);

    _systemBackHandle = handleSystemBack;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPhoneBottomNavBarVisible();
        _syncExpandedPlayerSystemChrome();
        if (widget.embeddedInShellFooter) {
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
      _lastSyncedRoutePath = path;
      _syncPhoneBottomNavBarVisible();
    }
  }

  @override
  void didUpdateWidget(covariant QuranPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneBottomNavBarVisible != widget.phoneBottomNavBarVisible) {
      _syncPhoneBottomNavBarVisible();
    }
  }

  @override
  void deactivate() {
    QuranPlayerSystemBackCoordinator.setIntercepts(false);
    QuranPlayerSystemBackCoordinator.unbind(handle: _systemBackHandle);
    context
        .read<QuranPlayerChromeNotifier>()
        .clearSystemNavigationBarColorOverride();
    super.deactivate();
  }

  @override
  void dispose() {
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

  /// Edge-to-edge nav is transparent; publish the queue sheet color app-wide
  /// so [TilawaApp] does not reset the gesture strip to white each frame.
  void _syncExpandedPlayerSystemChrome() {
    if (!mounted) {
      return;
    }
    final QuranPlayerChromeNotifier notifier = context
        .read<QuranPlayerChromeNotifier>();
    final bool overlayActive =
        _expandController.value > 0.01 &&
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
        return;
      }
      if (!_portalController.isShowing) {
        _portalController.show();
      }
      _syncExpandedPlayerSystemChrome();
    });
  }

  /// Expand the player to full-screen.
  ///
  /// Uses [Curves.easeOutCubic] for a smooth slide-up like YouTube Music
  /// (no overshoot — [Curves.easeOutBack] reads as a bounce, not YT).
  void expand() {
    HapticFeedback.lightImpact();
    _isCollapsing = false;
    _expandController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Collapse the player back to the mini bar.
  void collapse() {
    _isCollapsing = true;
    _expandController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Phone shell: animate sheet + mini in one overlay layer to avoid desync.
  bool get _animateShellInOverlay =>
      widget.embeddedInShellFooter && _expandController.isAnimating;

  void _onExpandAnimationStatus(AnimationStatus status) {
    if (!mounted) {
      return;
    }
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (_expandController.value <= 0.01) {
        _isCollapsing = false;
      }
      if (_expandController.value >= 0.99) {
        _isCollapsing = false;
      }
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
    final bool showBar = _expandController.value < threshold;
    if (n.value != showBar) {
      n.value = showBar;
    }
  }

  /// Mini bar fade: fast hide on expand, linear reveal on collapse.
  double _miniOpacityForProgress(double progress) {
    if (_isCollapsing) {
      return (1 - progress).clamp(0.0, 1.0);
    }
    return (1 - progress * 2.5).clamp(0.0, 1.0);
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
    final bool phoneNavVisible =
        !hideNavWhenExpanded || progress < threshold;
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

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final primaryDelta = details.primaryDelta ?? 0;
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

    final screenHeight = context.viewportHeight;
    // Negative primaryDelta = dragging up = expanding
    final delta = -primaryDelta / screenHeight;
    _expandController.value =
        (_expandController.value + delta * context.tokens.playerDragSensitivity)
            .clamp(0.0, 1.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final tokens = context.tokens;
    final primaryVelocity = details.primaryVelocity ?? 0;
    if (_dismissOffsetY > 0) {
      if (primaryVelocity > tokens.playerDismissVelocityThreshold ||
          _dismissOffsetY > tokens.playerDismissThreshold) {
        _dismissWithUndo();
      } else {
        _animateDismissReset();
      }
      return;
    }

    final negVelocity = -primaryVelocity;
    if (negVelocity > tokens.playerVelocityThreshold ||
        _expandController.value > tokens.playerProgressThreshold) {
      expand();
    } else if (negVelocity < -tokens.playerVelocityThreshold ||
        _expandController.value <= tokens.playerProgressThreshold) {
      collapse();
    }
  }

  /// Cancel the dismiss gesture and spring back.
  void _animateDismissReset() {
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
    HapticFeedback.lightImpact();
    context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.stopAudio());
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('QuranPlayerWidget');

    if (widget.embeddedInShellFooter) {
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
      return const SizedBox.shrink();
    }

    final Rect hostRect = MatrixUtils.transformRect(
      layoutInfo.childPaintTransform,
      Offset.zero & layoutInfo.childSize,
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
            onExpandDragUpdate: _onVerticalDragUpdate,
            onExpandDragEnd: _onVerticalDragEnd,
          ),
        );

        return AnimatedBuilder(
          animation: _expandController,
          child: expandedPlayer,
          builder: (context, expandedChild) {
            // [AnimationController.animateTo] already applies the curve; do
            // not transform progress again or collapse feels sluggish.
            final progress = _expandController.value;
            final double collapseStart = hostRect.bottom;

            // Mini player fades quickly on expand; linear reveal on collapse.
            final miniOpacity = _miniOpacityForProgress(progress);
            final miniSlideY = (1 - miniOpacity) * _miniPlayerHeight * 0.35;
            final bool showExpandedSheet =
                progress > 0.001 && expandedChild != null;
            final bool animateShellInOverlay = _animateShellInOverlay;

            final Widget miniPlayer = Opacity(
              opacity: miniOpacity,
              child: Transform.translate(
                offset: Offset(0, miniSlideY),
                child: _MiniPlayerTransition(
                  progress: progress,
                  audio: audio,
                  dismissAnimController: _dismissAnimController,
                  dismissAnimation: _dismissAnimation,
                  dismissOffsetY: _dismissOffsetY,
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
                    if (progress > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Theme.of(context).colorScheme.scrim
                                .withValues(alpha: progress * 0.5),
                          ),
                        ),
                      ),
                    if (showExpandedSheet)
                      _ExpandedPlayerMotion(
                        progress: progress,
                        screenHeight: screenHeight,
                        collapseStart: collapseStart,
                        sheetOpacity: _isCollapsing ? progress.clamp(0.0, 1.0) : 1.0,
                        child: expandedChild,
                      ),
                    if (animateShellInOverlay)
                      Positioned(
                        top: collapseStart - _miniPlayerHeight,
                        left: 0,
                        right: 0,
                        height: _miniPlayerHeight,
                        child: miniPlayer,
                      ),
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
                        ignoring: progress >
                            context.tokens.playerIgnorePointerThreshold,
                        child: miniPlayer,
                      ),
              );
            }

            final double bottomInset = _miniPlayerBottomInsetForProgress(
              context,
              progress,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                SizedBox(
                  height: screenHeight,
                  width: overlaySize.width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (progress > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Theme.of(context).colorScheme.scrim
                                  .withValues(alpha: progress * 0.5),
                            ),
                          ),
                        ),
                      if (showExpandedSheet)
                        _ExpandedPlayerMotion(
                          progress: progress,
                          screenHeight: screenHeight,
                          collapseStart: collapseStart,
                          sheetOpacity: _isCollapsing ? progress.clamp(0.0, 1.0) : 1.0,
                          child: expandedChild,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomInset - miniSlideY,
                  height: _miniPlayerHeight,
                  child: IgnorePointer(
                    ignoring: miniOpacity < 0.01,
                    child: miniPlayer,
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
    required this.progress,
    required this.screenHeight,
    required this.collapseStart,
    required this.sheetOpacity,
    required this.child,
  });

  final double progress;
  final double screenHeight;
  final double collapseStart;
  final double sheetOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheetOffsetY = (screenHeight - collapseStart) * (1 - progress);
    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, sheetOffsetY),
        child: Opacity(
          opacity: sheetOpacity.clamp(0.0, 1.0),
          child: child,
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
    required this.dismissAnimController,
    required this.dismissAnimation,
    required this.dismissOffsetY,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onTap,
    required this.onClose,
  });

  final double progress;
  final AudioEntity audio;
  final AnimationController dismissAnimController;
  final Animation<double>? dismissAnimation;
  final double dismissOffsetY;
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
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
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
    required this.onExpandDragUpdate,
    required this.onExpandDragEnd,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final Animation<double> expandAnimation;
  final GestureDragUpdateCallback onExpandDragUpdate;
  final GestureDragEndCallback onExpandDragEnd;

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
    if (mounted) {
      setState(() {});
    }
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
                              final double sheetHeight =
                                  _queueController.isAttached
                                  ? _queueController.size *
                                        constraints.maxHeight
                                  : _queuePeekSize * constraints.maxHeight;

                              return Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    bottom: sheetHeight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragUpdate: (details) {
                                        if (_queueAtPeek) {
                                          widget.onExpandDragUpdate(details);
                                        }
                                      },
                                      onVerticalDragEnd: (details) {
                                        if (_queueAtPeek) {
                                          widget.onExpandDragEnd(details);
                                        }
                                      },
                                      child: _YtMusicNowPlayingStage(
                                        state: widget.state,
                                        audio: widget.audio,
                                        queueReveal: _queueReveal,
                                        onCollapse: widget.onCollapse,
                                      ),
                                    ),
                                  ),
                                  DraggableScrollableSheet(
                                    controller: _queueController,
                                    initialChildSize: _queuePeekSize,
                                    minChildSize: _queuePeekSize,
                                    maxChildSize: _queueFullSize,
                                    snap: true,
                                    snapSizes: const <double>[
                                      _queuePeekSize,
                                      _queueMidSize,
                                      _queueFullSize,
                                    ],
                                    builder: (context, scrollController) {
                                      return _PlayerQueueSheet(
                                        scrollController: scrollController,
                                        queueController: _queueController,
                                        sheetParentHeight:
                                            constraints.maxHeight,
                                        snapSizes: const <double>[
                                          _queuePeekSize,
                                          _queueMidSize,
                                          _queueFullSize,
                                        ],
                                        state: widget.state,
                                        currentAudio: widget.audio,
                                      );
                                    },
                                  ),
                                ],
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
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final double queueReveal;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final bool showCompactBar = queueReveal > 0.62;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool tightStage = constraints.maxHeight < 140;

        if (showCompactBar || tightStage) {
          return _CompactNowPlayingBar(
            audio: audio,
            state: state,
            onCollapse: onCollapse,
            opacity: showCompactBar
                ? ((queueReveal - 0.62) / 0.25).clamp(0.0, 1.0)
                : 1.0,
          );
        }

        final double artReveal =
            (1 - (queueReveal / 0.55).clamp(0.0, 1.0));
        final double maxArtHeight =
            constraints.maxHeight * 0.45 * artReveal;
        final bool showArt = artReveal > 0.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceLarge,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight * 0.35,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showArt) ...[
                              _PlayerArtAtom(
                                artUri: audio.artUri,
                                maxHeight: maxArtHeight,
                              ),
                              SizedBox(height: tokens.spaceLarge),
                            ],
                            _PlayerMetadataMolecule(
                              title: audio.title,
                              artist: audio.artist,
                              centerAlign: true,
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
      child: Padding(
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
    );
  }
}

class _ExpandedPlayerLandscape extends StatelessWidget {
  const _ExpandedPlayerLandscape({
    required this.state,
    required this.audio,
    required this.onCollapse,
    required this.onDismiss,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Positioned.fill(
      child: SafeArea(
        child: Stack(
          children: [
            // Header: Metadata and Navigation
            Positioned(
              top: tokens.spaceSmall,
              left: isRtl ? null : tokens.spaceMedium,
              right: isRtl ? tokens.spaceMedium : null,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      FluentIcons.chevron_down_24_regular,
                      color: palette.foreground,
                      size: tokens.iconSizeLarge,
                    ),
                    onPressed: onCollapse,
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      onPressed: () =>
                          _showExpandedPlayerMenu(context, state),
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
  });

  final String title;
  final String? artist;
  final bool centerAlign;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final TextStyle? titleStyle = context
        .responsiveStyle((t) => t.titleLarge)
        ?.copyWith(color: palette.foreground, fontWeight: FontWeight.w600);
    final TextAlign textAlign = centerAlign ? TextAlign.center : TextAlign.start;
    final CrossAxisAlignment crossAlign = centerAlign
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.stretch;
    return Column(
      crossAxisAlignment: crossAlign,
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
        SizedBox(height: tokens.spaceExtraSmall),
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
          child: Text(
            artist ?? context.l10n.unknownReciter,
            style: context
                .responsiveStyle((t) => t.bodyMedium)
                ?.copyWith(
                  color: palette.secondary,
                ),
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
              children: [
                Icon(
                  icon,
                  color: palette.foreground,
                  size: tokens.iconSizeMedium,
                ),
                if (label != null) ...[
                  SizedBox(width: tokens.spaceExtraSmall),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
  const _PlayerArtAtom({this.artUri, this.maxHeight});

  final String? artUri;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final Widget artwork = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      child: artUri != null
          ? CachedNetworkImage(
              imageUrl: artUri!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _buildDefaultArt(context),
            )
          : _buildDefaultArt(context),
    );

    final Widget sizedArt = maxHeight != null
        ? SizedBox(
            height: maxHeight,
            width: double.infinity,
            child: artwork,
          )
        : AspectRatio(aspectRatio: 16 / 9, child: artwork);

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
    final double progress =
        data == null || data.duration.inMilliseconds == 0
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
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, _MiniPlayerSnapshot>(
      selector: _MiniPlayerSnapshot.fromState,
      builder: (context, snapshot) {
        return _YtMusicMiniPlayerBody(
          audio: audio,
          snapshot: snapshot,
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
    required this.snapshot,
    required this.onTap,
    required this.onClose,
  });

  final AudioEntity audio;
  final _MiniPlayerSnapshot snapshot;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final bool sleepTimerEnabled = context
        .watch<SettingsCubit>()
        .state
        .isSleepTimerEnabled;
    final Widget? artwork = audio.artUri == null
        ? null
        : ClipRRect(
            borderRadius: BorderRadius.circular(barTokens.artworkRadius),
            child: CachedNetworkImage(
              imageUrl: audio.artUri!,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          );

    return Semantics(
      identifier: QuranPlayerSemanticsIds.miniPlayer,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TilawaMediaPlayerBar(
            layoutWidth: constraints.maxWidth,
            title: audio.title,
            subtitle: audio.artist ?? context.l10n.unknownReciter,
            artwork: artwork,
            progress: snapshot.progress,
            isPlaying: snapshot.isPlaying,
            canGoPrevious: snapshot.canGoPrevious,
            canGoNext: snapshot.canGoNext,
            isSleepTimerActive: snapshot.isSleepTimerActive,
            isSleepTimerEnabled: sleepTimerEnabled,
            onTap: onTap,
            onClose: onClose,
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

/// Drag handle that resizes the queue [DraggableScrollableSheet] between snap
/// points (peek ↔ full) instead of only scrolling the list.
class _PlayerQueueSheetHandle extends StatelessWidget {
  const _PlayerQueueSheetHandle({
    required this.controller,
    required this.sheetParentHeight,
    required this.snapSizes,
    required this.color,
  });

  final DraggableScrollableController controller;
  final double sheetParentHeight;
  final List<double> snapSizes;
  final Color color;

  static const Duration _snapAnimationDuration = Duration(milliseconds: 280);

  void _snapToNearest() {
    if (!controller.isAttached || snapSizes.isEmpty) {
      return;
    }
    final double size = controller.size;
    double nearest = snapSizes.first;
    double minDistance = (size - nearest).abs();
    for (final double snap in snapSizes) {
      final double distance = (size - snap).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = snap;
      }
    }
    controller.animateTo(
      nearest,
      duration: _snapAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleMinMax() {
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
    controller.animateTo(
      target,
      duration: _snapAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double minSize = snapSizes.reduce((double a, double b) => a < b ? a : b);
    final double maxSize = snapSizes.reduce((double a, double b) => a > b ? a : b);

    return Semantics(
      identifier: QuranPlayerSemanticsIds.queueSheetHandle,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleMinMax,
        onVerticalDragUpdate: (DragUpdateDetails details) {
          if (!controller.isAttached || sheetParentHeight <= 0) {
            return;
          }
          final double nextSize = (controller.size -
                  details.delta.dy / sheetParentHeight)
              .clamp(minSize, maxSize);
          controller.jumpTo(nextSize);
        },
        onVerticalDragEnd: (_) => _snapToNearest(),
        child: TilawaSheetHandle(
          color: color,
          enableDragToDismiss: false,
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
    required this.snapSizes,
    required this.state,
    required this.currentAudio,
  });

  final ScrollController scrollController;
  final DraggableScrollableController queueController;
  final double sheetParentHeight;
  final List<double> snapSizes;
  final AudioPlayerState state;
  final AudioEntity currentAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final List<AudioEntity> queue =
        state.playbackState?.queue ?? <AudioEntity>[];
    final int? currentIndex = state.playbackState?.currentIndex;
    final String sourceLabel =
        currentAudio.album ??
        currentAudio.artist ??
        context.l10n.unknownReciter;
    final Color queueSheetColor = quranPlayerQueueSheetColor(colorScheme);

    final BorderRadius sheetRadius = BorderRadius.vertical(
      top: Radius.circular(tokens.radiusExtraLarge),
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
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: tokens.opacityEmphasis,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
              ),
            ),
            if (queue.length > 1)
              SliverReorderableList(
                itemBuilder: (context, index) {
                  final AudioEntity item = queue[index];
                  final bool isCurrent = currentIndex == index;
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey<String>(item.id),
                    index: index,
                    child: Semantics(
                      identifier: QuranPlayerSemanticsIds.queueItem(item.id),
                      button: true,
                      child: _QueueTrackTile(
                        audio: item,
                        isCurrent: isCurrent,
                        isPlaying: isCurrent && state.isPlaying,
                        subtitle: item.artist != null &&
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
                    tokens.spaceLarge + MediaQuery.paddingOf(context).bottom,
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

