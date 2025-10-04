import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/queue_state.dart';
import 'package:muzakri/widgets/control_buttons.dart';
import 'package:muzakri/widgets/seek_bar.dart';
import 'package:rxdart/rxdart.dart';

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
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FluentIcons.arrow_down_24_regular),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.currentPlaying),
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
                                      FluentIcons.music_note_1_20_regular,
                                      color: Theme.of(context).primaryColor,
                                      size: 100,
                                    );
                                  },
                                )
                              : Icon(
                                  FluentIcons.music_note_1_20_regular,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

              // Progress bar with time display - matches BottomPlayer pattern
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData =
                        snapshot.data ??
                        PositionData(
                          position: Duration.zero,
                          bufferedPosition: Duration.zero,
                          duration: Duration.zero,
                        );

                    return Column(
                      children: [
                        // Time display - matches bottom player pattern
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(positionData.position),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                              ),
                              Text(
                                _formatDuration(positionData.duration),
                                style: Theme.of(context).textTheme.bodySmall
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
                        // SeekBar
                        SeekBar(
                          duration: positionData.duration,
                          position: positionData.position,
                          bufferedPosition: positionData.bufferedPosition,
                          onChangeEnd: (newPosition) {
                            globalAudioHandler.seek(newPosition);
                          },
                        ),
                      ],
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
