import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/audio_player/domain/entities/player_background_configuration.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../../features/audio_player/presentation/widgets/background_source_dialog.dart';
import '../../features/audio_player/presentation/widgets/player_background_layer.dart';
import '../../features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../helpers/show_slider_dialog.dart';
import '../models/position_data.dart';

/// A YouTube/Spotify-style sliding player panel.
///
/// When collapsed, shows a mini player bar at the bottom.
/// Tap or swipe up to expand to a full-screen player.
/// Swipe down or tap the chevron to collapse back.
class QuranPlayerWidget extends StatefulWidget {
  const QuranPlayerWidget({
    super.key,
    this.bottomNavBarHeight = 0,
    this.isKeyboardOpen = false,
    this.phoneBottomNavBarVisible,
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
  /// `bottomNavBarHeight` must match what the host shell passes to the
  /// [QPlayer] mounted on this route. Standalone routes that
  /// mount their own player without a nav bar should pass 0.
  static double collapsedFootprint(
    BuildContext context, {
    double bottomNavBarHeight = 0,
    bool hostAbsorbsBottomSafeArea = false,
  }) =>
      collapsedHeight(context) +
      bottomNavBarHeight +
      (hostAbsorbsBottomSafeArea ? 0 : context.floatingBottomPadding);

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

  @override
  State<QuranPlayerWidget> createState() => QuranPlayerWidgetState();
}

class QuranPlayerWidgetState extends State<QuranPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;

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

    _expandController.addStatusListener((status) {
      debugPrint(
        '[QPlayer] expandController status=${status.name}, value=${_expandController.value.toStringAsFixed(3)}',
      );
    });
    _expandController.addListener(_syncPhoneBottomNavBarVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPhoneBottomNavBarVisible();
    });
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

  /// Expand the player to full-screen.
  ///
  /// Uses [Curves.easeOutBack] for a spring-like overshoot that feels
  /// like YouTube Music's player sheet expansion.
  void expand() {
    HapticFeedback.lightImpact();
    debugPrint(
      '[QPlayer] expand() called, current=${_expandController.value}, status=${_expandController.status}',
    );
    _expandController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
    );
  }

  /// Collapse the player back to the mini bar.
  ///
  /// Uses [Curves.easeOutCubic] for a smooth, natural deceleration.
  /// Avoids [Curves.easeInOutCubicEmphasized] which stalls visually
  /// (lingers at ~0.8–0.9 then snaps to 0).
  void collapse() {
    debugPrint(
      '[QPlayer] collapse() called, current=${_expandController.value}, status=${_expandController.status}',
    );
    _expandController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncPhoneBottomNavBarVisible() {
    final ValueNotifier<bool>? n = widget.phoneBottomNavBarVisible;
    if (n == null || !mounted) return;
    final double threshold = context.tokens.playerProgressThreshold;
    final bool showBar = _expandController.value < threshold;
    if (n.value != showBar) {
      n.value = showBar;
    }
  }

  void _ensurePhoneBottomNavBarShown() {
    final ValueNotifier<bool>? n = widget.phoneBottomNavBarVisible;
    if (n == null || n.value) return;
    n.value = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final primaryDelta = details.primaryDelta ?? 0;
    debugPrint(
      '[QPlayer] dragUpdate delta=$primaryDelta, expand=${_expandController.value.toStringAsFixed(3)}, dismissOffsetY=$_dismissOffsetY',
    );

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
    debugPrint(
      '[QPlayer] dragEnd velocity=$primaryVelocity, expand=${_expandController.value.toStringAsFixed(3)}, dismissOffsetY=$_dismissOffsetY',
    );

    if (_dismissOffsetY > 0) {
      if (primaryVelocity > tokens.playerDismissVelocityThreshold ||
          _dismissOffsetY > tokens.playerDismissThreshold) {
        debugPrint('[QPlayer] dragEnd → dismiss (velocity)');
        _dismissWithUndo();
      } else {
        debugPrint('[QPlayer] dragEnd → reset dismiss');
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

        if (!state.shouldShowBottomPlayer ||
            audio == null ||
            (widget.isKeyboardOpen && !isExpanding)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _ensurePhoneBottomNavBarShown();
          });
          return const SizedBox.shrink();
        }

        final screenHeight = context.viewportHeight;

        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _expandController,
            builder: (context, _) {
              final progress = _expandController.value;

              // Bottom inset above the layout bottom / overlaid nav. When the
              // host stacks bottom chrome below this subtree
              // ([hostAbsorbsBottomSafeArea]), skip [floatingBottomPadding] so we
              // do not double-count the home indicator already inside the bar.
              final double layoutBottomInset =
                  widget.hostAbsorbsBottomSafeArea &&
                      widget.bottomNavBarHeight <= 0
                  ? 0.0
                  : context.floatingBottomPadding;
              final bottomInset = widget.bottomNavBarHeight > 0
                  ? widget.bottomNavBarHeight
                  : layoutBottomInset;

              // Bottom sheet slide:
              // The expanded player translates from fully off-screen
              // (progress=0, translateY=screenHeight) to fully on-screen
              // (progress=1, translateY=0). This is the standard pattern
              // used by YouTube Music and Spotify.
              final sheetOffsetY = screenHeight * (1 - progress);

              // Mini player fades and slides to avoid overlapping with the
              // expanded player. During expand: slides down and fades out.
              // During collapse: slides up from below and fades in.
              final miniOpacity = (1 - progress * 2).clamp(0.0, 1.0);
              final miniSlideY = (1 - miniOpacity) * _miniPlayerHeight;

              return SizedBox(
                height: screenHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop scrim — only while expanding; omit at progress==0
                    // so no full-screen layer sits above the scaffold behind the
                    // bottom nav.
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
                    // Expanded player — slides up from below during expand,
                    // slides down below during collapse.
                    if (progress > 0.01)
                      Transform.translate(
                        offset: Offset(0, sheetOffsetY),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _onVerticalDragUpdate,
                          onVerticalDragEnd: _onVerticalDragEnd,
                          child: _ExpandedPlayerOrganism(
                            state: state,
                            audio: audio,
                            onCollapse: collapse,
                            onDismiss: _dismissWithUndo,
                            expandProgress: 0,
                          ),
                        ),
                      ),
                    // Mini player — slides down and fades out during expand
                    // to avoid overlapping with the arriving expanded player.
                    // Slides up from below during collapse.
                    if (progress < 0.55)
                      Positioned(
                        bottom: bottomInset - miniSlideY,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: miniOpacity,
                          child: SizedBox(
                            height: _miniPlayerHeight,
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
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
          tokens.spaceTiny,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TilawaMediaPlayerBar(
              layoutWidth: constraints.maxWidth,
              title: audio.title,
              subtitle: audio.artist ?? context.l10n.unknownReciter,
              artwork: audio.artUri == null
                  ? null
                  : CachedNetworkImage(
                      imageUrl: audio.artUri.toString(),
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                      placeholder: (context, url) => const SizedBox.shrink(),
                    ),
              progress:
                  state.positionData?.duration.inMilliseconds.toDouble() == 0
                  ? 0.0
                  : (state.positionData?.position.inMilliseconds ?? 0) /
                        (state.positionData?.duration.inMilliseconds ?? 1),
              progressBarOverride: const _MiniPlayerProgressBar(),
              isPlaying: state.isPlaying,
              canGoPrevious: state.canGoPrevious,
              canGoNext: state.canGoNext,
              isSleepTimerActive: state.isSleepTimerActive,
              isSleepTimerEnabled: context
                  .watch<SettingsCubit>()
                  .state
                  .isSleepTimerEnabled,
              onPlayPause: () {
                context.read<AudioPlayerBloc>().add(
                  state.isPlaying
                      ? const AudioPlayerEvent.pauseAudio()
                      : const AudioPlayerEvent.playAudio(),
                );
              },
              onPrevious: () {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToPrevious(),
                );
              },
              onNext: () {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToNext(),
                );
              },
              onSleepTimerTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const SleepTimerDialog(),
                );
              },
              onClose: onClose,
              onTap: onTap,
            );
          },
        ),
      ),
    );
  }
}

class _ExpandedPlayerOrganism extends StatelessWidget {
  const _ExpandedPlayerOrganism({
    required this.state,
    required this.audio,
    required this.onCollapse,
    required this.onDismiss,
    required this.expandProgress,
  });

  final AudioPlayerState state;
  final AudioEntity audio;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final double expandProgress;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final topPadding = MediaQuery.paddingOf(context).top;

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
        elevation: expandProgress * 16,
        shape: const RoundedRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            const PlayerBackgroundLayer(),
            Positioned.fill(
              child: BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
                builder: (context, bgState) {
                  if (bgState.config.type == PlayerBackgroundType.custom) {
                    return const SizedBox.shrink();
                  }
                  return audio.artUri != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: audio.artUri!,
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

            // Content
            if (isLandscape)
              _ExpandedPlayerLandscape(
                state: state,
                audio: audio,
                onCollapse: onCollapse,
                onDismiss: onDismiss,
              )
            else
              Positioned.fill(
                child: SafeArea(
                  child: TilawaContentBounds(
                    kind: TilawaContentKind.media,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PlayerHeaderMolecule(
                                  state: state,
                                  onCollapse: onCollapse,
                                  onDismiss: onDismiss,
                                ),

                                // Artwork
                                _PlayerArtAtom(
                                  artUri: audio.artUri,
                                  maxHeight: constraints.maxHeight * 0.35,
                                ),

                                // Metadata
                                _PlayerMetadataMolecule(
                                  title: audio.title,
                                  artist: audio.artist,
                                ),

                                // Progress & Controls (Thumb-friendly zone)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _ExpandedProgressBar(),
                                    SizedBox(height: tokens.spaceLarge),
                                    _PlayerMainControlsMolecule(
                                      state: state,
                                      isPlaying: state.isPlaying,
                                    ),
                                    SizedBox(height: tokens.spaceMedium),
                                    _PlayerSecondaryControlsMolecule(
                                      state: state,
                                    ),
                                    SizedBox(height: tokens.spaceExtraLarge),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Drag handle
            if (!isLandscape)
              Positioned(
                top: topPadding + 8,
                left: 0,
                right: 0,
                child: TilawaSheetHandle(
                  omitTopMargin: true,
                  color: Colors.white.withAlpha(0x4D),
                ),
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
              child: _PlayerMainControlsMolecule(
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
                              onTap: () => showSliderDialog(
                                context: context,
                                title: context.l10n.adjustVolume,
                                divisions: 10,
                                min: 0.0,
                                max: 1.0,
                                value: state.volume,
                                onChanged: (v) => context
                                    .read<AudioPlayerBloc>()
                                    .add(AudioPlayerEvent.setVolume(v)),
                              ),
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

class _PlayerHeaderMolecule extends StatelessWidget {
  const _PlayerHeaderMolecule({
    required this.state,
    required this.onCollapse,
    required this.onDismiss,
  });

  final AudioPlayerState state;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          FluentIcons.chevron_down_24_regular,
          color: Colors.white,
          size: tokens.iconSizeLarge + tokens.spaceExtraSmall,
        ),
        onPressed: onCollapse,
      ),
      title: Text(
        context.l10n.currentPlaying,
        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
      actions: [
        if (context.watch<SettingsCubit>().state.isSleepTimerEnabled)
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
                builder: (_) => const SleepTimerDialog(),
              );
            },
          ),
        IconButton(
          icon: const Icon(FluentIcons.image_24_regular, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BackgroundSourceDialog(
                onSourceSelected: (source) {
                  context.read<PlayerBackgroundCubit>().pickImage(source);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlayerMetadataMolecule extends StatelessWidget {
  const _PlayerMetadataMolecule({required this.title, this.artist});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceExtraLarge),
      child: Column(
        children: [
          Text(
            title,
            style: context
                .responsiveStyle((t) => t.headlineMedium)
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            artist ?? context.l10n.unknownReciter,
            style: context
                .responsiveStyle((t) => t.bodyLarge)
                ?.copyWith(
                  color: Colors.white.withValues(alpha: tokens.opacityEmphasis),
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlayerMainControlsMolecule extends StatelessWidget {
  const _PlayerMainControlsMolecule({
    required this.state,
    required this.isPlaying,
  });

  final AudioPlayerState state;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final previousIcon = isRtl
        ? FluentIcons.next_24_filled
        : FluentIcons.previous_24_filled;
    final nextIcon = isRtl
        ? FluentIcons.previous_24_filled
        : FluentIcons.next_24_filled;
    // Thumb-friendly layout: Primary actions (Play/Next) grouped and sized
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        IconButton(
          icon: Icon(
            previousIcon,
            color: state.canGoPrevious
                ? Colors.white
                : Colors.white.withValues(alpha: tokens.opacitySubtle),
            size: tokens.iconSizeLarge,
          ),
          onPressed: state.canGoPrevious
              ? () => context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToPrevious(),
                )
              : null,
        ),
        SizedBox(width: tokens.spaceLarge),

        // Play/Pause (Centerpiece)
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

        SizedBox(width: tokens.spaceLarge),

        // Next (Most common thumb action after play)
        IconButton(
          icon: Icon(
            nextIcon,
            color: state.canGoNext
                ? Colors.white
                : Colors.white.withValues(alpha: tokens.opacitySubtle),
            size: tokens.iconSizeLarge,
          ),
          onPressed: state.canGoNext
              ? () => context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToNext(),
                )
              : null,
        ),
      ],
    );
  }
}

class _PlayerSecondaryControlsMolecule extends StatelessWidget {
  const _PlayerSecondaryControlsMolecule({required this.state});

  final AudioPlayerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Row(
      mainAxisAlignment: .spaceAround,
      children: [
        TilawaIconActionButton(
          icon: FluentIcons.speaker_2_24_regular,
          onTap: () => showSliderDialog(
            context: context,
            title: context.l10n.adjustVolume,
            divisions: 10,
            min: 0.0,
            max: 1.0,
            value: state.volume,
            onChanged: (v) => context.read<AudioPlayerBloc>().add(
              AudioPlayerEvent.setVolume(v),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.playbackSpeed,
          value: '${state.speed.toStringAsFixed(1)}x',
          // docs/tilawa_brand.md §5: tappable chip-grammar affordance — pill radius
          // resolved from the 44 dp interactive minimum; spacing from tokens.
          // White-on-dark colors are intentional (fixed dark-palette context
          // for the expanded player; DESIGN §12 export/composer exception).
          child: Material(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              tokens.resolveRadius(
                family: TilawaRadiusFamily.pill,
                height: tokens.minInteractiveDimension,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                tokens.resolveRadius(
                  family: TilawaRadiusFamily.pill,
                  height: tokens.minInteractiveDimension,
                ),
              ),
              onTap: () => showSliderDialog(
                context: context,
                title: context.l10n.playbackSpeed,
                divisions: 8,
                min: 0.5,
                max: 2.5,
                value: state.speed,
                onChanged: (s) => context.read<AudioPlayerBloc>().add(
                  AudioPlayerEvent.setSpeed(s),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceMedium,
                  vertical: tokens.spaceSmall,
                ),
                child: Text(
                  '${state.speed.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
  const _PlayerArtAtom({this.artUri, required this.maxHeight});

  final String? artUri;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final artSize = tokens.contentMaxWidthMedia / 4.2; // approx 280
    return SizedBox(
      width: artSize,
      height: maxHeight.clamp(0.0, artSize),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
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

class _MiniPlayerProgressBar extends StatelessWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, double>(
      selector: (state) {
        final PositionData pos =
            state.positionData ??
            const PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );
        if (pos.duration.inMilliseconds <= 0) return 0.0;
        return (pos.position.inMilliseconds / pos.duration.inMilliseconds)
            .clamp(0.0, 1.0);
      },
      builder: (context, progress) {
        return LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.primaryContainer.withValues(
            alpha: tokens.opacitySubtle,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          minHeight: tokens.progressHeight,
        );
      },
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
              SeekBar(
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
