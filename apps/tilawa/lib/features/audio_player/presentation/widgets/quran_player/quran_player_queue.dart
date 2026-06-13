part of 'quran_player_widget.dart';

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
    required this.queueIndexCache,
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
  final QuranPlayerQueueIndexCache queueIndexCache;
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
    final int queueGeneration = state.playbackState?.queueGeneration ?? 0;
    final Map<String, int> queueIndexById = queueIndexCache.indexByIdFor(
      queue: queue,
      queueGeneration: queueGeneration,
    );
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
