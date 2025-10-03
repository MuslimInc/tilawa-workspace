import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/queue_state.dart';
import 'package:muzakri/widgets/control_buttons.dart';
import 'package:muzakri/widgets/seek_bar.dart';
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
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
            PositionData(Duration.zero, Duration.zero, Duration.zero);

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
                          // Seek bar with time display
                          Column(
                            children: [
                              // Time display
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position.position),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                    Text(
                                      _formatDuration(position.duration),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Seek bar
                              Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: SeekBar(
                                  duration: position.duration,
                                  position: position.position,
                                  onChangeEnd: (newPosition) {
                                    globalAudioHandler.seek(newPosition);
                                  },
                                ),
                              ),
                            ],
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
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Previous button
                                IconButton(
                                  icon: const Icon(Icons.skip_previous),
                                  onPressed: canGoPrevious
                                      ? () =>
                                            globalAudioHandler.skipToPrevious()
                                      : null,
                                ),

                                // Play/Pause button
                                IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    if (isPlaying) {
                                      globalAudioHandler.pause();
                                    } else {
                                      globalAudioHandler.play();
                                    }
                                  },
                                ),

                                // Next button
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
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

class ExpandedPlayerScreen extends StatefulWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  State<ExpandedPlayerScreen> createState() => _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends State<ExpandedPlayerScreen> {
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
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: StreamBuilder<MediaItem?>(
        stream: globalAudioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;

          if (mediaItem == null) {
            return const Center(
              child: Text(
                'No audio playing',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              // Album art
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Hero(
                      tag: 'album_art',
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: mediaItem.artUri != null
                              ? Image.network(
                                  mediaItem.artUri.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.music_note,
                                      color: Theme.of(context).primaryColor,
                                      size: 100,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: Theme.of(context).primaryColor,
                                  size: 100,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      mediaItem.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mediaItem.artist ?? mediaItem.album ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData =
                        snapshot.data ??
                        PositionData(
                          Duration.zero,
                          Duration.zero,
                          Duration.zero,
                        );
                    return SeekBar(
                      duration: positionData.duration,
                      position: positionData.position,
                      onChangeEnd: (newPosition) {
                        globalAudioHandler.seek(newPosition);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Controls
              ControlButtons(globalAudioHandler),

              const SizedBox(height: 40),

              // Queue
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StreamBuilder<QueueState>(
                    stream: globalAudioHandler.queueState,
                    builder: (context, snapshot) {
                      final queueState = snapshot.data ?? QueueState.empty;
                      final queue = queueState.queue;

                      if (queue.isEmpty) {
                        return const Center(
                          child: Text(
                            'No items in queue',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final item = queue[index];
                          final isCurrentItem = index == queueState.queueIndex;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentItem
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCurrentItem
                                    ? Theme.of(context).primaryColor
                                    : Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrentItem
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isCurrentItem
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isCurrentItem
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item.artist ?? '',
                                style: const TextStyle(color: Colors.white60),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () =>
                                  globalAudioHandler.skipToQueueItem(index),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
