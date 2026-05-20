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

import '../../features/audio_player/domain/entities/audio_modes.dart';
import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../../features/audio_player/presentation/widgets/background_source_dialog.dart';
import '../../features/audio_player/presentation/widgets/player_background_layer.dart';
import '../../features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../helpers/show_slider_dialog.dart';
import '../models/position_data.dart';
import 'quran_player_chrome.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncPhoneBottomNavBarVisible();
        if (widget.embeddedInShellFooter) {
          _schedulePortalVisibilitySync();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  void dispose() {
    _expandController.removeListener(_syncPhoneBottomNavBarVisible);
    _expandController.dispose();
    _dismissAnimController.dispose();
    super.dispose();
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
    });
  }

  /// Expand the player to full-screen.
  ///
  /// Uses [Curves.easeOutCubic] for a smooth slide-up like YouTube Music
  /// (no overshoot — [Curves.easeOutBack] reads as a bounce, not YT).
  void expand() {
    HapticFeedback.lightImpact();
    _expandController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Collapse the player back to the mini bar.
  ///
  /// Uses [Curves.easeOutCubic] for a smooth, natural deceleration.
  /// Avoids [Curves.easeInOutCubicEmphasized] which stalls visually
  /// (lingers at ~0.8–0.9 then snaps to 0).
  void collapse() {
    _expandController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncPhoneBottomNavBarVisible() {
    final ValueNotifier<bool>? n = widget.phoneBottomNavBarVisible;
    if (n == null || !mounted) return;
    final String location = _currentRoutePath();
    final bool hideNavWhenExpanded =
        AppShellRoutePolicy.shouldHideBottomNavWhenPlayerExpanded(location);
    final double threshold = context.tokens.playerProgressThreshold;
    final bool showBar =
        !hideNavWhenExpanded || _expandController.value < threshold;
    if (n.value != showBar) {
      n.value = showBar;
    }
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
      buildWhen: (previous, current) =>
          previous.currentAudio != current.currentAudio ||
          previous.shouldShowBottomPlayer != current.shouldShowBottomPlayer ||
          previous.isPlaying != current.isPlaying ||
          previous.canGoPrevious != current.canGoPrevious ||
          previous.canGoNext != current.canGoNext ||
          previous.isSleepTimerActive != current.isSleepTimerActive ||
          previous.volume != current.volume ||
          previous.speed != current.speed ||
          previous.dismissedAudioId != current.dismissedAudioId,
      listener: (context, state) {
        // Reset dismiss animation so the mini player is not offset off-screen
        // from a previous dismiss gesture.
        if (_dismissAnimation != null ||
            _dismissAnimController.value != 0 ||
            _dismissOffsetY != 0) {
          _dismissAnimation = null;
          _dismissAnimController.value = 0;
          _dismissOffsetY = 0;
        }
        if (state.failure != null) {
          ToastUtils.showErrorToast(state.failure!.localizedMessage(context));
        }
      },
      builder: (context, state) {
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
        final Listenable animation = widget.phoneBottomNavBarVisible == null
            ? _expandController
            : Listenable.merge(<Listenable>[
                _expandController,
                widget.phoneBottomNavBarVisible!,
              ]);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final progress = _expandController.value;

            // Bottom sheet slide: expanded player rides up from below the
            // mini-player slot (YouTube Music attaches the sheet to the bar).
            final double expandCurve = Curves.easeOutCubic.transform(progress);
            final double collapseStart = hostRect.bottom;
            final sheetOffsetY =
                (screenHeight - collapseStart) * (1 - expandCurve);

            // Mini player fades quickly so the expanding sheet reads as one
            // continuous surface (YT cross-fades the bar into the sheet).
            final miniOpacity = (1 - expandCurve * 2.5).clamp(0.0, 1.0);
            final miniSlideY = (1 - miniOpacity) * _miniPlayerHeight * 0.35;

            final Widget miniPlayer = Opacity(
              opacity: miniOpacity,
              child: Transform.translate(
                offset: Offset(0, miniSlideY),
                child: _MiniPlayerTransition(
                  progress: progress,
                  state: state,
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
                            color: Colors.black.withValues(
                              alpha: progress * 0.5,
                            ),
                          ),
                        ),
                      ),
                    if (progress > 0.01)
                      Transform.translate(
                        offset: Offset(0, sheetOffsetY),
                        child: Transform.scale(
                          scale: 0.94 + 0.06 * expandCurve,
                          alignment: Alignment.bottomCenter,
                          child: _ExpandedPlayerOrganism(
                            state: state,
                            audio: audio,
                            onCollapse: collapse,
                            onDismiss: _dismissWithUndo,
                            expandProgress: expandCurve,
                            onExpandDragUpdate: _onVerticalDragUpdate,
                            onExpandDragEnd: _onVerticalDragEnd,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            if (miniAnchoredInFooter) {
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  if (progress < 0.55) Positioned.fill(child: miniPlayer),
                ],
              );
            }

            final double bottomInset = _resolveBottomInset(context);

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
                              color: Colors.black.withValues(
                                alpha: progress * 0.5,
                              ),
                            ),
                          ),
                        ),
                      if (progress > 0.01)
                        Transform.translate(
                          offset: Offset(0, sheetOffsetY),
                          child: Transform.scale(
                            scale: 0.94 + 0.06 * expandCurve,
                            alignment: Alignment.bottomCenter,
                            child: _ExpandedPlayerOrganism(
                              state: state,
                              audio: audio,
                              onCollapse: collapse,
                              onDismiss: _dismissWithUndo,
                              expandProgress: expandCurve,
                              onExpandDragUpdate: _onVerticalDragUpdate,
                              onExpandDragEnd: _onVerticalDragEnd,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (progress < 0.55)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomInset - miniSlideY,
                    height: _miniPlayerHeight,
                    child: miniPlayer,
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

/// Wraps the mini player organism with swipe-to-dismiss gesture handling
/// and the dismiss translation animation. Kept separate so the heavy
/// `AnimatedBuilder` subtree rebuilds only when the dismiss controller
/// ticks, not on every state rebuild of the parent.
class _MiniPlayerTransition extends StatelessWidget {
  const _MiniPlayerTransition({
    required this.progress,
    required this.state,
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
  final AudioPlayerState state;
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
            state: state,
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
    required this.state,
    required this.audio,
    required this.onTap,
    required this.onClose,
  });

  final AudioPlayerState state;
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
          state: state,
          audio: audio,
          onTap: onTap,
          onClose: onClose,
        ),
      ),
    );
  }
}

class _ExpandedPlayerOrganism extends StatefulWidget {
  const _ExpandedPlayerOrganism({
    required this.state,
    required this.audio,
    required this.onCollapse,
    required this.onDismiss,
    required this.expandProgress,
    required this.onExpandDragUpdate,
    required this.onExpandDragEnd,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final double expandProgress;
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

  @override
  void initState() {
    super.initState();
    _queueController.addListener(_onQueueSheetChanged);
  }

  @override
  void dispose() {
    _queueController.removeListener(_onQueueSheetChanged);
    _queueController.dispose();
    super.dispose();
  }

  void _onQueueSheetChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _ExpandedPlayerOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandProgress >= 1.0 && oldWidget.expandProgress < 1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _queueController.isAttached) {
          _queueController.jumpTo(_queuePeekSize);
        }
      });
    }
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
    final tokens = Theme.of(context).tokens;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: Colors.black,
        elevation: widget.expandProgress * 16,
        shape: const RoundedRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const PlayerBackgroundLayer(),
            Positioned.fill(
              child: BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
                builder: (context, bgState) {
                  if (bgState.config.type == PlayerBackgroundType.custom) {
                    return const SizedBox.shrink();
                  }
                  return widget.audio.artUri != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.audio.artUri!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withValues(
                                alpha: tokens.opacityMedium,
                              ),
                            ),
                          ],
                        )
                      : Container(color: Colors.black);
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
              Positioned.fill(
                child: SafeArea(
                  child: TilawaContentBounds(
                    kind: TilawaContentKind.media,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double sheetHeight = _queueController.isAttached
                            ? _queueController.size * constraints.maxHeight
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
                                  expandProgress: widget.expandProgress,
                                  queueReveal: _queueReveal,
                                  onCollapse: widget.onCollapse,
                                ),
                              ),
                            ),
                            DraggableScrollableSheet(
                              controller: _queueController,
                              initialChildSize: _queuePeekSize,
                              minChildSize: 0.12,
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
      ),
    );
  }
}

/// Now-playing body that shrinks and fades as the queue sheet slides up.
class _YtMusicNowPlayingStage extends StatelessWidget {
  const _YtMusicNowPlayingStage({
    required this.state,
    required this.audio,
    required this.expandProgress,
    required this.queueReveal,
    required this.onCollapse,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final double expandProgress;
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceLarge,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlayerArtAtom(artUri: audio.artUri),
                    SizedBox(height: tokens.spaceLarge),
                    _PlayerMetadataMolecule(
                      title: audio.title,
                      artist: audio.artist,
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    _PlayerActionPillsMolecule(state: state),
                    SizedBox(height: tokens.spaceMedium),
                    const _ExpandedProgressBar(),
                    SizedBox(height: tokens.spaceLarge),
                    _PlayerTransportRow(
                      state: state,
                      isPlaying: state.isPlaying,
                    ),
                    SizedBox(height: tokens.spaceMedium),
                  ],
                ),
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
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.15,
        );
    final TextStyle? artistStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(
          color: Colors.white.withValues(alpha: tokens.opacityEmphasis),
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
                color: Colors.white,
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
                color: Colors.white,
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
                      color: Colors.white,
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audio.artist ?? context.l10n.unknownReciter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(
                            alpha: tokens.opacityEmphasis,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Dismiss and more
            Positioned(
              top: tokens.spaceSmall,
              left: isRtl ? tokens.spaceMedium : null,
              right: isRtl ? null : tokens.spaceMedium,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FluentIcons.image_24_regular,
                      color: Colors.white,
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
                ],
              ),
            ),

            // Center: Primary Controls
            Center(
              child: _PlayerTransportRow(
                state: state,
                isPlaying: state.isPlaying,
              ),
            ),

            // Bottom: Seek Bar and secondary actions
            Positioned(
              bottom: tokens.spaceSmall + tokens.spaceExtraLarge,
              left: tokens.spaceLarge,
              right: tokens.spaceLarge,
              child: Builder(
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ExpandedProgressBar(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceLarge,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TilawaIconActionButton(
                              icon: FluentIcons.speaker_2_24_regular,
                              onTap: () {
                                final AudioPlayerBloc bloc = context
                                    .read<AudioPlayerBloc>();
                                showSliderDialog(
                                  context: context,
                                  title: context.l10n.adjustVolume,
                                  divisions: 10,
                                  min: 0.0,
                                  max: 1.0,
                                  value: state.volume,
                                  onChanged: (double v) {
                                    bloc.add(AudioPlayerEvent.setVolume(v));
                                  },
                                );
                              },
                            ),
                            Row(
                              children: [
                                if (context
                                    .watch<SettingsCubit>()
                                    .state
                                    .isSleepTimerEnabled)
                                  IconButton(
                                    icon: Icon(
                                      state.isSleepTimerActive
                                          ? FluentIcons.timer_24_filled
                                          : FluentIcons.timer_24_regular,
                                      color: state.isSleepTimerActive
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            const SleepTimerDialog(),
                                      );
                                    },
                                  ),
                                TilawaIconActionButton(
                                  icon: FluentIcons.more_horizontal_24_regular,
                                  onTap: () => _showPlaybackActions(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraLarge),
                    ],
                  );
                },
              ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              FluentIcons.chevron_down_24_regular,
              color: Colors.white,
              size: tokens.iconSizeLarge,
            ),
            onPressed: onCollapse,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              FluentIcons.more_vertical_24_regular,
              color: Colors.white,
            ),
            onPressed: () => _showExpandedPlayerMenu(context, state),
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
              ListTile(
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
            ListTile(
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
            ListTile(
              leading: const Icon(FluentIcons.stop_24_regular),
              title: Text(sheetContext.l10n.stopPlayback),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.stopAudio(),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _PlayerMetadataMolecule extends StatelessWidget {
  const _PlayerMetadataMolecule({required this.title, this.artist});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final TextStyle? titleStyle = context
        .responsiveStyle((t) => t.titleLarge)
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          artist ?? context.l10n.unknownReciter,
          style: context
              .responsiveStyle((t) => t.bodyMedium)
              ?.copyWith(
                color: Colors.white.withValues(alpha: tokens.opacityEmphasis),
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    final bool shuffleOn = state.shuffleMode == AudioShuffleMode.all;
    final Color enabled = Colors.white;
    final Color disabled = Colors.white.withValues(
      alpha: tokens.opacitySubtle,
    );
    final IconData repeatIcon = switch (state.repeatMode) {
      AudioRepeatMode.one => Icons.repeat_one,
      AudioRepeatMode.all => Icons.repeat,
      AudioRepeatMode.none => Icons.repeat,
    };
    final bool repeatActive = state.repeatMode != AudioRepeatMode.none;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, color: shuffleOn ? enabled : disabled),
          onPressed: () {
            final AudioShuffleMode next = shuffleOn
                ? AudioShuffleMode.none
                : AudioShuffleMode.all;
            context.read<AudioPlayerBloc>().add(
              AudioPlayerEvent.setShuffleMode(next),
            );
          },
          tooltip: context.l10n.shufflePlaylist,
        ),
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: state.canGoPrevious ? enabled : disabled,
            size: tokens.iconSizeLarge,
          ),
          onPressed: state.canGoPrevious
              ? () => context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToPrevious(),
                )
              : null,
        ),
        _PlayerPlayPauseAtom(
          isPlaying: isPlaying,
          onTap: () {
            context.read<AudioPlayerBloc>().add(
              isPlaying
                  ? const AudioPlayerEvent.pauseAudio()
                  : const AudioPlayerEvent.playAudio(),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: state.canGoNext ? enabled : disabled,
            size: tokens.iconSizeLarge,
          ),
          onPressed: state.canGoNext
              ? () => context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToNext(),
                )
              : null,
        ),
        IconButton(
          icon: Icon(
            repeatIcon,
            color: repeatActive ? enabled : disabled,
          ),
          onPressed: () {
            final AudioRepeatMode next = switch (state.repeatMode) {
              AudioRepeatMode.none => AudioRepeatMode.all,
              AudioRepeatMode.all => AudioRepeatMode.one,
              AudioRepeatMode.one => AudioRepeatMode.none,
            };
            context.read<AudioPlayerBloc>().add(
              AudioPlayerEvent.setRepeatMode(next),
            );
          },
        ),
      ],
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
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _YtMusicActionPill(
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
          SizedBox(width: tokens.spaceSmall),
          _YtMusicActionPill(
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
          if (sleepEnabled) ...[
            SizedBox(width: tokens.spaceSmall),
            _YtMusicActionPill(
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
        color: Colors.white.withValues(alpha: 0.12),
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
                Icon(icon, color: Colors.white, size: tokens.iconSizeMedium),
                if (label != null) ...[
                  SizedBox(width: tokens.spaceExtraSmall),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
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

Future<void> _showPlaybackActions(BuildContext context) async {
  final bool? shouldOpenStopConfirm = await showTilawaModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(bottom: sheetContext.floatingBottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            ListTile(
              leading: const Icon(FluentIcons.stop_24_regular),
              title: Text(context.l10n.stopPlayback),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      );
    },
  );

  if (shouldOpenStopConfirm != true || !context.mounted) {
    return;
  }

  final bool? shouldStop = await showTilawaModalBottomSheet<bool>(
    context: context,
    builder: (dialogContext) {
      return Padding(
        padding: EdgeInsets.only(bottom: dialogContext.floatingBottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            ListTile(
              title: Text(context.l10n.stopPlayback),
              subtitle: Text(context.l10n.stopPlaybackConfirmMessage),
            ),
            OverflowBar(
              spacing: 12,
              children: [
                TilawaButton(
                  text: context.l10n.cancel,
                  variant: TilawaButtonVariant.ghost,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TilawaButton(
                  text: context.l10n.stopPlayback,
                  variant: TilawaButtonVariant.danger,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  if (shouldStop == true && context.mounted) {
    context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.stopAudio());
  }
}

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

class _PlayerArtAtom extends StatelessWidget {
  const _PlayerArtAtom({this.artUri});

  final String? artUri;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: artUri != null
            ? CachedNetworkImage(
                imageUrl: artUri!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildDefaultArt(context),
              )
            : _buildDefaultArt(context),
      ),
    );
  }

  Widget _buildDefaultArt(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Container(
      color: Colors.white.withValues(alpha: tokens.opacitySubtle),
      child: Center(
        child: Icon(
          FluentIcons.music_note_2_24_filled,
          size: tokens.iconSizeLarge * 3.3, // approx 80
          color: Colors.white.withValues(alpha: tokens.opacityEmphasis / 3),
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
    final buttonSize = tokens.iconSizeLarge * 3.3; // approx 80
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: tokens.opacityMedium),
            blurRadius: tokens.spaceLarge,
            spreadRadius: tokens.spaceTiny,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? FluentIcons.pause_48_filled : FluentIcons.play_48_filled,
          color: Colors.black,
          size: tokens.iconSizeLarge * 1.6, // approx 40
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _YtMusicMiniPlayer extends StatelessWidget {
  const _YtMusicMiniPlayer({
    required this.state,
    required this.audio,
    required this.onTap,
    required this.onClose,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double progress =
        state.positionData?.duration.inMilliseconds.toDouble() == 0
        ? 0.0
        : (state.positionData?.position.inMilliseconds ?? 0) /
              (state.positionData?.duration.inMilliseconds ?? 1);

    return Material(
      color: const Color(0xFF1C1C1C),
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.white.withValues(
                alpha: tokens.opacitySubtle,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceMedium,
                tokens.spaceSmall,
                tokens.spaceSmall,
                tokens.spaceSmall,
              ),
              child: Row(
                children: [
                  _MiniArtwork(artUri: audio.artUri, size: 44),
                  SizedBox(width: tokens.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          audio.artist ?? context.l10n.unknownReciter,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(
                                  alpha: tokens.opacityEmphasis,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPlaying
                          ? FluentIcons.pause_24_filled
                          : FluentIcons.play_24_filled,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      context.read<AudioPlayerBloc>().add(
                        state.isPlaying
                            ? const AudioPlayerEvent.pauseAudio()
                            : const AudioPlayerEvent.playAudio(),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      FluentIcons.dismiss_24_regular,
                      color: Colors.white.withValues(
                        alpha: tokens.opacityEmphasis,
                      ),
                      size: tokens.iconSizeMedium,
                    ),
                    onPressed: onClose,
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

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.artUri, required this.size});

  final String? artUri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
        child: artUri == null
            ? ColoredBox(
                color: Colors.white.withValues(alpha: tokens.opacitySubtle),
                child: Icon(
                  FluentIcons.music_note_2_24_filled,
                  color: Colors.white54,
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

class _PlayerQueueSheet extends StatelessWidget {
  const _PlayerQueueSheet({
    required this.scrollController,
    required this.state,
    required this.currentAudio,
  });

  final ScrollController scrollController;
  final AudioPlayerState state;
  final AudioEntity currentAudio;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final List<AudioEntity> queue =
        state.playbackState?.queue ?? <AudioEntity>[];
    final int? currentIndex = state.playbackState?.currentIndex;
    final String sourceLabel =
        currentAudio.album ??
        currentAudio.artist ??
        context.l10n.unknownReciter;

    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radiusExtraLarge),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: TilawaSheetHandle(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.surfaceContainer.withValues(
                      alpha: tokens.opacityEmphasis,
                    ),
              ),
            ),
          ),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(
                        alpha: tokens.opacityEmphasis,
                      ),
                    ),
                  ),
                  Text(
                    sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
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
                  child: _QueueTrackTile(
                    audio: item,
                    isCurrent: isCurrent,
                    isPlaying: isCurrent && state.isPlaying,
                    onTap: () {
                      if (!isCurrent) {
                        context.read<AudioPlayerBloc>().add(
                          AudioPlayerEvent.skipToQueueItem(index),
                        );
                      }
                    },
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
            padding: EdgeInsets.only(bottom: tokens.spaceLarge),
          ),
        ],
      ),
    );
  }
}

class _QueueTrackTile extends StatelessWidget {
  const _QueueTrackTile({
    required this.audio,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final AudioEntity audio;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Material(
      color: isCurrent
          ? Colors.white.withValues(alpha: 0.08)
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
                      color: Colors.white,
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                      ),
                    ),
                    Text(
                      audio.artist ?? context.l10n.unknownReciter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(
                          alpha: tokens.opacityEmphasis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.drag_handle,
                color: Colors.white.withValues(alpha: tokens.opacityEmphasis),
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
        final seekActiveColor = Colors.white;
        final seekThumbColor = Colors.white;
        final seekBufferedColor = Colors.white.withValues(
          alpha: tokens.opacityMedium,
        );
        final seekInactiveColor = Colors.white.withValues(
          alpha: tokens.opacitySubtle,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: SeekBar(
                  duration: positionData.duration,
                  position: positionData.position,
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
              SizedBox(height: tokens.spaceExtraSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(positionData.position),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(
                        alpha: tokens.opacityEmphasis - 0.1,
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(positionData.duration),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(
                        alpha: tokens.opacityEmphasis - 0.1,
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

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  } else {
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
