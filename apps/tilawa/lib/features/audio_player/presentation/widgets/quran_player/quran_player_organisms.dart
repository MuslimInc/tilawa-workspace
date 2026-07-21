part of 'quran_player_widget.dart';
// ---------------------------------------------------------------------------
// Organisms
// ---------------------------------------------------------------------------

/// Stable [AnimatedBuilder.child] so footer mini drag survives expand ticks.
@immutable
class _PlayerAnimatedSubtree extends StatelessWidget {
  const _PlayerAnimatedSubtree({
    required this.expandedPlayer,
    required this.footerMiniGesture,
  });

  final Widget expandedPlayer;
  final Widget footerMiniGesture;

  @override
  Widget build(BuildContext context) => expandedPlayer;
}

/// Slide/scale motion for the expanded sheet during expand/collapse.
///
/// Kept separate from [_ExpandedPlayerOrganism] so only this lightweight
/// layer rebuilds each animation tick.
class _ExpandedPlayerMotion extends StatelessWidget {
  const _ExpandedPlayerMotion({
    required this.sheetMotionT,
    required this.screenHeight,
    required this.miniPlayerHeight,
    required this.sheetOpacity,
    required this.semanticLabel,
    required this.child,
  });

  final double sheetMotionT;
  final double screenHeight;
  final double miniPlayerHeight;
  final double sheetOpacity;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = sheetMotionT.clamp(0.0, 1.0);
    final double sheetHeight =
        miniPlayerHeight + (screenHeight - miniPlayerHeight) * t;
    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: SizedBox(
              height: sheetHeight,
              width: double.infinity,
              child: Opacity(
                opacity: sheetOpacity.clamp(0.0, 1.0),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: screenHeight,
                  maxHeight: screenHeight,
                  child: SizedBox(
                    height: screenHeight,
                    width: double.infinity,
                    child: child,
                  ),
                ),
              ),
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
    super.key,
    required this.progress,
    required this.audio,
    this.useHeroArtwork = false,
    required this.identityChromeOpacity,
    this.retainExpandDragGestures = false,
    required this.dismissAnimController,
    required this.dismissAnimation,
    required this.dismissOffsetX,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onTap,
    this.onSubtitleTap,
    required this.onClose,
    this.shellDockLayout = false,
  }) : shellPillLayout = false;

  final double progress;
  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;

  /// Keeps the footer mini drag recognizer alive past
  /// [DesignTokens.playerIgnorePointerThreshold] during expand/collapse drag.
  final bool retainExpandDragGestures;
  final AnimationController dismissAnimController;
  final Animation<double>? dismissAnimation;
  final double dismissOffsetX;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragUpdateCallback onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;
  final bool shellDockLayout;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring:
          !retainExpandDragGestures &&
          progress > context.tokens.playerIgnorePointerThreshold,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        child: AnimatedBuilder(
          animation: dismissAnimController,
          builder: (context, child) {
            final offset = dismissAnimation?.value ?? dismissOffsetX;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: _MiniPlayerOrganism(
            audio: audio,
            useHeroArtwork: useHeroArtwork,
            identityChromeOpacity: identityChromeOpacity,
            onTap: onTap,
            onSubtitleTap: onSubtitleTap,
            onClose: onClose,
            shellPillLayout: shellPillLayout,
            shellDockLayout: shellDockLayout,
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
    this.onSubtitleTap,
    required this.onClose,
    this.shellPillLayout = false,
    this.shellDockLayout = false,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;
  final bool shellDockLayout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _YtMusicMiniPlayer(
        audio: audio,
        useHeroArtwork: useHeroArtwork,
        identityChromeOpacity: identityChromeOpacity,
        onTap: onTap,
        onSubtitleTap: onSubtitleTap,
        onClose: onClose,
        shellPillLayout: shellPillLayout,
        shellDockLayout: shellDockLayout,
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

  factory _ExpandedPlayerPalette.resolve(
    BuildContext context, {
    required bool onImageBackdrop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final barTokens = theme.componentTokens.mediaPlayerBar;

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

  final QuranPlayerQueueIndexCache _queueIndexCache =
      QuranPlayerQueueIndexCache();

  double? _lastExpandValue;

  bool _queueHandleDragMoved = false;
  bool _suppressQueueHandleTap = false;

  /// Positive [dy] = finger moved down (sheet shrinks).
  double _queueHandleDragNetDy = 0;
  double _stageDragNetDy = 0;
  bool _stagePlayerCollapseDragActive = false;

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
    _stagePlayerCollapseDragActive = false;
  }

  void _onStageDragUpdate(double deltaDy) {
    _stageDragNetDy += deltaDy;
  }

  void _handleStageVerticalDragUpdate(
    DragUpdateDetails details, {
    required double sheetParentHeight,
    required List<double> snapSizes,
  }) {
    final double dy = details.delta.dy;
    _onStageDragUpdate(dy);
    applyQuranPlayerStageVerticalDragDelta(
      deltaY: dy,
      collapseDragActive: _stagePlayerCollapseDragActive,
      onArmCollapseDrag: () {
        _stagePlayerCollapseDragActive = true;
        widget.onPlayerExpandDragStart?.call();
      },
      onPlayerCollapseDragUpdate: (double delta) {
        widget.onPlayerExpandDragUpdate?.call(delta);
      },
      onQueueSheetDragUp: (double delta) {
        _stagePlayerCollapseDragActive = false;
        _QueueSheetSnap.applyDragDelta(
          controller: _queueController,
          sheetParentHeight: sheetParentHeight,
          snapSizes: snapSizes,
          deltaDy: delta,
        );
      },
    );
  }

  void _handleStageVerticalDragEnd(DragEndDetails details) {
    QuranPlayerDebugLog.log(
      'queue.stageDragEnd',
      <String, Object?>{
        'velocity': (details.primaryVelocity ?? 0).toStringAsFixed(1),
        'size': _queueController.isAttached
            ? _queueController.size.toStringAsFixed(3)
            : null,
        'collapseDrag': _stagePlayerCollapseDragActive,
      },
    );
    if (_stagePlayerCollapseDragActive) {
      widget.onPlayerExpandDragEnd?.call(details);
      _stagePlayerCollapseDragActive = false;
      _stageDragNetDy = 0;
      return;
    }
    if (_stageDragNetDy < -0.5) {
      _onStageDragEnd(details);
      _stageDragNetDy = 0;
      return;
    }
    _onStageDragEnd(details);
    _stageDragNetDy = 0;
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
    final _ExpandedPlayerPalette palette = _ExpandedPlayerPalette.resolve(
      context,
      onImageBackdrop: hasCustomBackground,
    );
    final Brightness statusBarIconBrightness = hasCustomBackground
        ? Brightness.light
        : theme.brightness == Brightness.dark
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
                                listenable: _queueController,
                                builder: (context, _) {
                                  final double sheetHeight =
                                      _queueController.isAttached
                                      ? _queueController.size *
                                            constraints.maxHeight
                                      : _queuePeekSize * constraints.maxHeight;
                                  // Expand progress chrome is applied by
                                  // [_ExpandDrivenStageChrome] via
                                  // [PlayerExpandMetricsScope] so this heavy
                                  // stage+queue subtree does not rebuild on
                                  // every expand tick.
                                  final double queueReveal = _queueReveal;

                                  final Widget stage = _YtMusicNowPlayingStage(
                                    state: widget.state,
                                    audio: widget.audio,
                                    queueReveal: queueReveal,
                                    onCollapse: widget.onCollapse,
                                    useHeroArtwork: widget.useHeroArtwork,
                                    onStageVerticalDragStart: (_) {
                                      _onStageDragStart();
                                      QuranPlayerDebugLog.log(
                                        'queue.stageDragStart',
                                        <String, Object?>{
                                          'atPeek': _queueAtPeek,
                                        },
                                      );
                                    },
                                    onStageVerticalDragUpdate: (details) {
                                      _handleStageVerticalDragUpdate(
                                        details,
                                        sheetParentHeight:
                                            constraints.maxHeight,
                                        snapSizes: snapSizes,
                                      );
                                    },
                                    onStageVerticalDragEnd:
                                        _handleStageVerticalDragEnd,
                                  );

                                  final Widget queueSheet =
                                      DraggableScrollableSheet(
                                        controller: _queueController,
                                        initialChildSize: _queuePeekSize,
                                        minChildSize: _queuePeekSize,
                                        maxChildSize: _queueFullSize,
                                        snap: true,
                                        snapSizes: snapSizes,
                                        builder: (context, scrollController) {
                                          return _PlayerQueueSheet(
                                            scrollController: scrollController,
                                            queueController: _queueController,
                                            queueIndexCache: _queueIndexCache,
                                            sheetParentHeight:
                                                constraints.maxHeight,
                                            peekSize: _queuePeekSize,
                                            snapSizes: snapSizes,
                                            state: widget.state,
                                            currentAudio: widget.audio,
                                            onCollapseToPeek:
                                                _collapseQueueSheetToPeek,
                                            onHandleTap: _onQueueHandleTap,
                                            onHandleDragStart:
                                                _onQueueHandleDragStart,
                                            onHandleDragUpdate:
                                                _onQueueHandleDragUpdate,
                                            onHandleDragEnd:
                                                _onQueueHandleDragEnd,
                                          );
                                        },
                                      );

                                  return _ExpandDrivenStageChrome(
                                    sheetHeight: sheetHeight,
                                    queueSheet: queueSheet,
                                    stage: stage,
                                    expandAnimation: widget.expandAnimation,
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

/// Fades centered stage chrome from [PlayerExpandMetricsScope] without
/// rebuilding artwork/metadata on every expand tick.
class _StageChromeFade extends StatelessWidget {
  const _StageChromeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double opacity =
        PlayerExpandMetricsScope.maybeOf(context)?.stageChromeOpacity ?? 1;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: child,
    );
  }
}

/// Applies expand-progress chrome (queue fade + stage inset) without
/// rebuilding the heavy stage/queue subtrees on every animation tick.
///
/// Depends on [PlayerExpandMetricsScope] from the overlay builder so only
/// this lightweight shell rebuilds when expand progress changes.
class _ExpandDrivenStageChrome extends StatelessWidget {
  const _ExpandDrivenStageChrome({
    required this.sheetHeight,
    required this.queueSheet,
    required this.stage,
    required this.expandAnimation,
  });

  final double sheetHeight;
  final Widget queueSheet;
  final Widget stage;
  final Animation<double> expandAnimation;

  @override
  Widget build(BuildContext context) {
    final PlayerExpandTransitionMetrics expandMetrics =
        PlayerExpandMetricsScope.maybeOf(context) ??
        PlayerExpandTransitionMetrics.compute(
          progress: expandAnimation.value,
          miniPlayerHeight: 0,
        );
    final double stageBottomInset = sheetHeight * expandMetrics.queueChromeT;

    return Stack(
      children: [
        Visibility(
          visible: expandMetrics.queueChromeT > 0.01,
          maintainState: true,
          maintainAnimation: true,
          child: Opacity(
            opacity: expandMetrics.queueChromeT,
            child: IgnorePointer(
              ignoring: expandMetrics.queueChromeT < 0.5,
              child: queueSheet,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: stageBottomInset,
          child: stage,
        ),
      ],
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
    required this.onStageVerticalDragStart,
    required this.onStageVerticalDragUpdate,
    required this.onStageVerticalDragEnd,
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
  final GestureDragStartCallback onStageVerticalDragStart;
  final GestureDragUpdateCallback onStageVerticalDragUpdate;
  final GestureDragEndCallback onStageVerticalDragEnd;
  final bool useHeroArtwork;

  @override
  Widget build(BuildContext context) {
    return QuranPlayerExpandedStageGestureScope(
      onCollapse: onCollapse,
      onVerticalDragStart: onStageVerticalDragStart,
      onVerticalDragUpdate: onStageVerticalDragUpdate,
      onVerticalDragEnd: onStageVerticalDragEnd,
      child: LayoutBuilder(
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
            return QuranPlayerExpandedStageQueueFocusedLayout(
              maxHeight: constraints.maxHeight,
              onVerticalDragStart: onStageVerticalDragStart,
              onVerticalDragUpdate: onStageVerticalDragUpdate,
              onVerticalDragEnd: onStageVerticalDragEnd,
              children: [
                _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
                _PlayerReciterHistorySection(audio: audio, state: state),
                _PlayerPlaybackCluster(
                  state: state,
                  queueReveal: queueReveal,
                ),
                SizedBox(height: tokens.spaceSmall),
              ],
            );
          }

          final tokens = Theme.of(context).tokens;

          return QuranPlayerExpandedStageDefaultLayout(
            header: _YtMusicPlayerHeader(state: state, onCollapse: onCollapse),
            onVerticalDragStart: onStageVerticalDragStart,
            onVerticalDragUpdate: onStageVerticalDragUpdate,
            onVerticalDragEnd: onStageVerticalDragEnd,
            centeredChrome: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
              child: _StageChromeFade(
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
            playbackCluster: _PlayerPlaybackCluster(
              state: state,
              queueReveal: queueReveal,
            ),
          );
        },
      ),
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
  final QuranPlayerQueueIndexCache _queueIndexCache =
      QuranPlayerQueueIndexCache();

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
    final String? reciterId = widget.audio.extras.getString(
      AudioExtrasKeys.reciterId,
    );
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
    final int queueGeneration =
        widget.state.playbackState?.queueGeneration ?? 0;
    final Map<String, int> indexBySurahId = _queueIndexCache.indexBySurahIdFor(
      queue: queue,
      queueGeneration: queueGeneration,
    );
    final int? index = indexBySurahId[history.surahId.toString()];
    if (index == null) {
      return;
    }
    final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
    bloc.add(AudioPlayerEvent.skipToQueueItem(index));
    final Duration? resumeAt = history.resumeInitialPosition;
    if (resumeAt != null) {
      bloc.add(AudioPlayerEvent.seekTo(resumeAt));
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

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final palette = _ExpandedPlayerPalette.of(context);
    final double rowHeight = barTokens.playPauseButtonSize;
    final BoxConstraints iconConstraints = BoxConstraints(
      minWidth: rowHeight,
      minHeight: rowHeight,
    );
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

    Widget buildContentRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
            icon: Icon(
              FluentIcons.chevron_down_24_regular,
              color: palette.foreground,
              size: tokens.iconSizeLarge,
            ),
            onPressed: onCollapse,
          ),
          _MiniArtwork(
            artUri: audio.artUri,
            size: kTilawaMediaPlayerBarCompactArtworkSize,
          ),
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
            constraints: iconConstraints,
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
      );
    }

    Widget buildProgressIndicator(double minHeight) {
      return BlocSelector<AudioPlayerBloc, AudioPlayerState, double>(
        selector: (state) => _MiniPlayerSnapshot.fromState(state).progress,
        builder: (context, progress) {
          return LinearProgressIndicator(
            value: progress,
            backgroundColor: palette.seekInactive,
            valueColor: AlwaysStoppedAnimation<Color>(palette.seekActive),
            minHeight: minHeight,
          );
        },
      );
    }

    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool boundedHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          if (!boundedHeight) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildProgressIndicator(tokens.progressHeight),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSmall,
                    vertical: tokens.spaceExtraSmall,
                  ),
                  child: buildContentRow(),
                ),
              ],
            );
          }

          final ({double topBand, double bottomBand}) bands =
              resolveTilawaMediaPlayerCollapsedBands(
                maxHeight: constraints.maxHeight,
                rowHeight: rowHeight,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: bands.topBand,
                child: bands.topBand <= 0
                    ? const SizedBox.shrink()
                    : ClipRect(
                        clipBehavior: Clip.hardEdge,
                        child: buildProgressIndicator(bands.topBand),
                      ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: tokens.spaceSmall,
                  end: tokens.spaceSmall,
                  bottom: bands.bottomBand,
                ),
                child: SizedBox(
                  height: rowHeight,
                  child: buildContentRow(),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          );
        },
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
        onTap: onCollapse,
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
      ),
    );
  }
}
