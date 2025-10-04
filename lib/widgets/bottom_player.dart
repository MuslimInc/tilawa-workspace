import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/queue_state.dart';
import 'package:rxdart/rxdart.dart';

class BottomPlayer extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onTap;

  const BottomPlayer({super.key, this.isVisible = true, this.onTap});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  Stream<Duration> get _bufferedPositionStream => globalAudioHandler
      .playbackState
      .map((state) => state.bufferedPosition)
      .distinct();

  Stream<Duration?> get _durationStream =>
      globalAudioHandler.mediaItem.map((item) => item?.duration).distinct();

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        AudioService.position,
        _bufferedPositionStream,
        _durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  Stream<Map<String, dynamic>> get _combinedStream =>
      Rx.combineLatest4<
        MediaItem?,
        PlaybackState,
        PositionData,
        QueueState,
        Map<String, dynamic>
      >(
        globalAudioHandler.mediaItem,
        globalAudioHandler.playbackState,
        _positionDataStream,
        globalAudioHandler.queueState,
        (mediaItem, playbackState, positionData, queueState) => {
          'mediaItem': mediaItem,
          'playbackState': playbackState,
          'positionData': positionData,
          'queueState': queueState,
        },
      );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(BottomPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _combinedStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final mediaItem = data?['mediaItem'] as MediaItem?;
        final playbackState = data?['playbackState'] as PlaybackState?;
        final positionData = data?['positionData'] as PositionData?;
        final queueState = data?['queueState'] as QueueState?;

        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final isPlaying = playbackState?.playing ?? false;
        final position =
            positionData ??
            PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        // Check if next/previous buttons should be enabled
        final currentIndex = playbackState?.queueIndex ?? 0;
        final queueLength = queueState?.queue.length ?? 0;
        final canGoNext = currentIndex < queueLength - 1;
        final canGoPrevious = currentIndex > 0;

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: Hero(
                tag: 'bottom_player',
                child: Material(
                  elevation: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar - Real time (YouTube Music style)
                          Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: position.duration.inMilliseconds > 0
                                    ? position.position.inMilliseconds /
                                          position.duration.inMilliseconds
                                    : 0.0,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),

                          // Main controls
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Album art or icon
                                Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                  ),
                                  child: mediaItem.artUri != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            mediaItem.artUri.toString(),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.music_note,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    size: 30,
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note,
                                          color: Theme.of(context).primaryColor,
                                          size: 30,
                                        ),
                                ),

                                const SizedBox(width: 12),

                                // Song info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mediaItem.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        mediaItem.artist ??
                                            mediaItem.album ??
                                            'Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Previous button
                                IconButton(
                                  icon: const Icon(
                                    FluentIcons.arrow_left_24_regular,
                                    size: 20,
                                  ),
                                  onPressed: canGoPrevious
                                      ? () =>
                                            globalAudioHandler.skipToPrevious()
                                      : null,
                                ),

                                // Play/Pause button - YouTube Music style
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? FluentIcons.pause_24_regular
                                          : FluentIcons.play_24_regular,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        globalAudioHandler.pause();
                                      } else {
                                        globalAudioHandler.play();
                                      }
                                    },
                                  ),
                                ),

                                // Next button
                                IconButton(
                                  icon: const Icon(
                                    FluentIcons.arrow_right_24_regular,
                                    size: 20,
                                  ),
                                  onPressed: canGoNext
                                      ? () => globalAudioHandler.skipToNext()
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
