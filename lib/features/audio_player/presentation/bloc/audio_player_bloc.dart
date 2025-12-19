import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../main.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../../../../shared/models/media_item_json.dart';
import '../../../../shared/models/position_data.dart';
import '../../../../shared/models/queue_state.dart';

part 'audio_player_bloc.freezed.dart';
part 'audio_player_event.dart';
part 'audio_player_state.dart';

@injectable
class AudioPlayerBloc extends HydratedBloc<AudioPlayerEvent, AudioPlayerState> {
  AudioPlayerBloc(this._audioHandler)
    : super(const AudioPlayerState(status: AudioPlayerStatus.initial)) {
    // State update events
    on<LoadAudioPlayerData>(_onLoadAudioPlayerData);
    on<UpdateMediaItem>(_onUpdateMediaItem);
    on<UpdatePlaybackState>(_onUpdatePlaybackState);
    on<UpdatePositionData>(_onUpdatePositionData);
    on<UpdateQueueState>(_onUpdateQueueState);
    on<UpdateVolume>(_onUpdateVolume);
    on<UpdateSpeed>(_onUpdateSpeed);

    // Audio control events
    on<PlayAudio>(_onPlayAudio);
    on<PauseAudio>(_onPauseAudio);
    on<StopAudio>(_onStopAudio);
    on<SkipToNext>(_onSkipToNext);
    on<SkipToPrevious>(_onSkipToPrevious);
    on<SeekTo>(_onSeekTo);
    on<SetVolume>(_onSetVolume);
    on<SetSpeed>(_onSetSpeed);
    on<SkipToQueueItem>(_onSkipToQueueItem);
    on<PlayFromQueue>(_onPlayFromQueue);
    on<UpdateQueue>(_onUpdateQueue);
    on<AddQueueItem>(_onAddQueueItem);
    on<RemoveQueueItem>(_onRemoveQueueItem);
    on<MoveQueueItem>(_onMoveQueueItem);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<SetShuffleMode>(_onSetShuffleMode);

    _setupAudioStreams();
  }
  final AudioPlayerHandler _audioHandler;

  void _setupAudioStreams() {
    // Listen to media item changes - start with current value if available
    final MediaItem? initialMediaItem = _audioHandler.mediaItem.valueOrNull;
    if (initialMediaItem != null) {
      // Emit current value immediately
      add(AudioPlayerEvent.updateMediaItem(initialMediaItem));
    }
    _audioHandler.mediaItem.listen((mediaItem) {
      add(AudioPlayerEvent.updateMediaItem(mediaItem));
    });

    // Listen to playback state changes - start with current value
    final PlaybackState? initialPlaybackState =
        _audioHandler.playbackState.valueOrNull;
    if (initialPlaybackState != null) {
      add(AudioPlayerEvent.updatePlaybackState(initialPlaybackState));
    }
    _audioHandler.playbackState.listen((playbackState) {
      add(AudioPlayerEvent.updatePlaybackState(playbackState));
    });

    // Listen to position data changes
    // Use runZoned to catch errors that occur during stream subscription
    // This handles cases where AudioService is not initialized (e.g., in tests)
    runZonedGuarded(
      () {
        _getPositionDataStream().listen(
          (positionData) {
            add(AudioPlayerEvent.updatePositionData(positionData));
          },
          onError: (error) {
            // Handle stream errors
            logger.d('Error in position stream: $error');
          },
          cancelOnError: false,
        );
      },
      (error, stackTrace) {
        // Catch errors that occur during stream creation/subscription
        // (e.g., AudioService not initialized)
        logger.d(
          'AudioService not initialized, position stream unavailable: $error',
        );
      },
    );

    // Listen to queue state changes
    _audioHandler.queueState.listen((queueState) {
      add(AudioPlayerEvent.updateQueueState(queueState));
    });

    // Listen to volume changes - start with current value
    _audioHandler.volume.startWith(_audioHandler.volume.value).listen((volume) {
      add(AudioPlayerEvent.updateVolume(volume));
    });

    // Listen to speed changes - start with current value
    _audioHandler.speed.startWith(_audioHandler.speed.value).listen((speed) {
      add(AudioPlayerEvent.updateSpeed(speed));
    });
  }

  Stream<Duration> get _bufferedPositionStream => _audioHandler.playbackState
      .map((state) => state.bufferedPosition)
      .distinct();

  Stream<Duration?> get _durationStream =>
      _audioHandler.mediaItem.map((item) => item?.duration).distinct();

  Stream<PositionData> _getPositionDataStream() {
    // Create the combined stream
    // If AudioService is not initialized, Rx.combineLatest3 will throw when subscribing
    // We'll catch this error in _setupAudioStreams
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      AudioService.position,
      _bufferedPositionStream,
      _durationStream,
      (position, bufferedPosition, duration) => PositionData(
        position: position,
        bufferedPosition: bufferedPosition,
        duration: duration ?? Duration.zero,
      ),
    );
  }

  Future<void> _onLoadAudioPlayerData(
    LoadAudioPlayerData event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // Get current values to restore state after restart
    final double currentVolume = _audioHandler.volume.value;
    final double currentSpeed = _audioHandler.speed.value;

    // Check if we have persisted queue data from previous session
    // But FIRST, ensure we don't overwrite an already active session (e.g. from background)
    final List<MediaItem> currentQueue = _audioHandler.queue.value;
    if (currentQueue.isNotEmpty) {
      logger.d(
        'Audio handler already has ${currentQueue.length} items. Skipping queue restoration.',
      );
    } else if (!event.restorePlayback) {
      logger.d('Playback restoration disabled via event parameter. Skipping.');
    } else if (state.queueState != null &&
        state.queueState!.queue.isNotEmpty &&
        state.queueState!.queueIndex != null) {
      logger.d(
        'Restoring persisted queue with ${state.queueState!.queue.length} items at index ${state.queueState!.queueIndex}',
      );

      try {
        // Restore the queue using playFromQueue
        await _audioHandler.playFromQueue(
          state.queueState!.queue,
          state.queueState!.queueIndex!,
        );

        // Restore the playback position if available
        if (state.positionData != null &&
            state.positionData!.position != Duration.zero) {
          logger.d(
            'Restoring playback position: ${state.positionData!.position}',
          );
          await _audioHandler.seek(state.positionData!.position);
        }

        // Pause playback - user needs to press play
        await _audioHandler.pause();

        logger.d('Successfully restored queue and position');
      } catch (e) {
        logger.d('Error restoring queue: $e');
      }
    }

    // Strategy: Get current item from queue using queueIndex from playbackState
    // This is more reliable than waiting for mediaItem stream which only emits on changes
    MediaItem? currentMediaItem;
    PlaybackState? currentPlaybackState;
    QueueState? currentQueueState;

    try {
      // Get queue state first - it contains the queue and current index
      currentQueueState = await _audioHandler.queueState.first.timeout(
        const Duration(milliseconds: 500),
      );

      // Get playback state to get the current queue index
      currentPlaybackState = await _audioHandler.playbackState.first.timeout(
        const Duration(milliseconds: 500),
      );

      // If we have queue state and playback state, get current item from queue
      if (currentPlaybackState.queueIndex != null) {
        final int queueIndex = currentPlaybackState.queueIndex!;
        if (queueIndex >= 0 && queueIndex < currentQueueState.queue.length) {
          currentMediaItem = currentQueueState.queue[queueIndex];
          logger.d(
            'Found current media item from queue at index $queueIndex: ${currentMediaItem.title}',
          );
        }
      }
    } catch (e) {
      logger.d('Error getting queue/playback state: $e');
    }

    // Fallback: If we couldn't get from queue, try mediaItem stream
    if (currentMediaItem == null) {
      try {
        currentMediaItem = await _audioHandler.mediaItem.first.timeout(
          const Duration(milliseconds: 500),
        );
        logger.d(
          'Got media item from stream: ${currentMediaItem?.title ?? 'null'}',
        );
      } catch (e) {
        logger.d('No media item found from stream: $e');
      }
    }

    // If we still don't have playback state, try to get it
    if (currentPlaybackState == null) {
      try {
        currentPlaybackState = await _audioHandler.playbackState.first.timeout(
          const Duration(milliseconds: 500),
        );
      } catch (e) {
        logger.d('No playback state found: $e');
      }
    }

    // If we have a media item, update the state immediately
    if (currentMediaItem != null) {
      logger.d(
        'Restoring audio player state with media item: ${currentMediaItem.title}',
      );
      emit(
        state.copyWith(
          status: AudioPlayerStatus.success,
          mediaItem: currentMediaItem,
          playbackState: currentPlaybackState,
          queueState: currentQueueState,
          volume: currentVolume,
          speed: currentSpeed,
        ),
      );
    } else {
      // No media item, just update status and settings
      logger.d('No media item to restore, updating settings only');
      emit(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          volume: currentVolume,
          speed: currentSpeed,
        ),
      );
    }
  }

  void _onUpdateMediaItem(
    UpdateMediaItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: event.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdatePlaybackState(
    UpdatePlaybackState event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: event.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdatePositionData(
    UpdatePositionData event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: event.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateQueueState(
    UpdateQueueState event,
    Emitter<AudioPlayerState> emit,
  ) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: event.queueState,
        volume: state.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateVolume(UpdateVolume event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: event.volume,
        speed: state.speed,
      ),
    );
  }

  void _onUpdateSpeed(UpdateSpeed event, Emitter<AudioPlayerState> emit) {
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: event.speed,
      ),
    );
  }

  // Audio control event handlers
  void _onPlayAudio(PlayAudio event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received PlayAudio event');
    _audioHandler.play();
  }

  void _onPauseAudio(PauseAudio event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received PauseAudio event');
    _audioHandler.pause();
  }

  void _onStopAudio(StopAudio event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received StopAudio event');
    _audioHandler.stop();
  }

  void _onSkipToNext(SkipToNext event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received SkipToNext event');
    _audioHandler.skipToNext();
  }

  void _onSkipToPrevious(SkipToPrevious event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received SkipToPrevious event');
    _audioHandler.skipToPrevious();
  }

  void _onSeekTo(SeekTo event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received SeekTo event: ${event.position}');
    _audioHandler.seek(event.position);
  }

  void _onSetVolume(SetVolume event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received SetVolume event: ${event.volume}');
    _audioHandler.setVolume(event.volume);
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: event.volume,
        speed: state.speed,
      ),
    );
  }

  void _onSetSpeed(SetSpeed event, Emitter<AudioPlayerState> emit) {
    logger.d('[AudioPlayerBloc] Received SetSpeed event: ${event.speed}');
    _audioHandler.setSpeed(event.speed);
    emit(
      state.copyWith(
        status: AudioPlayerStatus.success,
        mediaItem: state.mediaItem,
        playbackState: state.playbackState,
        positionData: state.positionData,
        queueState: state.queueState,
        volume: state.volume,
        speed: event.speed,
      ),
    );
  }

  void _onSkipToQueueItem(
    SkipToQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    logger.d(
      '[AudioPlayerBloc] Received SkipToQueueItem event: ${event.index}',
    );
    _audioHandler.skipToQueueItem(event.index);
  }

  void _onPlayFromQueue(PlayFromQueue event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received PlayFromQueue event: index=${event.index}, queueLength=${event.queue.length}',
    );
    _audioHandler.playFromQueue(event.queue, event.index);
  }

  void _onUpdateQueue(UpdateQueue event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received UpdateQueue event. Length: ${event.queue.length}',
    );
    _audioHandler.updateQueue(event.queue);
  }

  void _onAddQueueItem(AddQueueItem event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received AddQueueItem event: ${event.item.title}',
    );
    _audioHandler.addQueueItem(event.item);
  }

  void _onRemoveQueueItem(
    RemoveQueueItem event,
    Emitter<AudioPlayerState> emit,
  ) {
    logger.d(
      '[AudioPlayerBloc] Received RemoveQueueItem event: ${event.item.title}',
    );
    _audioHandler.removeQueueItem(event.item);
  }

  void _onMoveQueueItem(MoveQueueItem event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received MoveQueueItem event: ${event.currentIndex} -> ${event.newIndex}',
    );
    _audioHandler.moveQueueItem(event.currentIndex, event.newIndex);
  }

  void _onSetRepeatMode(SetRepeatMode event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received SetRepeatMode event: ${event.repeatMode}',
    );
    _audioHandler.setRepeatMode(event.repeatMode);
  }

  void _onSetShuffleMode(SetShuffleMode event, Emitter<AudioPlayerState> emit) {
    logger.d(
      '[AudioPlayerBloc] Received SetShuffleMode event: ${event.shuffleMode}',
    );
    _audioHandler.setShuffleMode(event.shuffleMode);
  }

  @override
  AudioPlayerState? fromJson(Map<String, dynamic> json) {
    try {
      final double volume = (json['volume'] as num?)?.toDouble() ?? 1.0;
      final double speed = (json['speed'] as num?)?.toDouble() ?? 1.0;

      // Restore queue if persisted
      List<MediaItem>? queue;
      int? queueIndex;
      if (json['queue'] != null) {
        try {
          queue = MediaItemJson.fromJsonList(json['queue'] as List<dynamic>);
          queueIndex = json['queueIndex'] as int?;
          logger.d(
            'Restored ${queue.length} items from persisted queue at index $queueIndex',
          );
        } catch (e) {
          logger.d('Error deserializing queue: $e');
        }
      }

      // Restore playback position if persisted
      PositionData? positionData;
      if (json['position'] != null) {
        try {
          final positionMs = json['position'] as int;
          positionData = PositionData(
            position: Duration(milliseconds: positionMs),
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
          );
          logger.d('Restored playback position: ${positionData.position}');
        } catch (e) {
          logger.d('Error deserializing position: $e');
        }
      }

      return AudioPlayerState(
        status: AudioPlayerStatus.initial,
        volume: volume,
        speed: speed,
        queueState: queue != null && queueIndex != null
            ? QueueState(
                queue: queue,
                queueIndex: queueIndex,
                shuffleIndices: null,
                repeatMode: AudioServiceRepeatMode.none,
              )
            : null,
        positionData: positionData,
      );
    } catch (e) {
      logger.d('Error in fromJson: $e');
      return const AudioPlayerState(status: AudioPlayerStatus.initial);
    }
  }

  @override
  Map<String, dynamic>? toJson(AudioPlayerState state) {
    try {
      final json = <String, dynamic>{
        'volume': state.volume,
        'speed': state.speed,
      };

      // Persist queue if available
      if (state.queueState != null &&
          state.queueState!.queue.isNotEmpty &&
          state.queueState!.queueIndex != null) {
        json['queue'] = MediaItemJson.toJsonList(state.queueState!.queue);
        json['queueIndex'] = state.queueState!.queueIndex;
        logger.d(
          'Persisting queue with ${state.queueState!.queue.length} items at index ${state.queueState!.queueIndex}',
        );
      }

      // Persist current playback position if available
      if (state.positionData != null &&
          state.positionData!.position != Duration.zero) {
        json['position'] = state.positionData!.position.inMilliseconds;
        logger.d(
          'Persisting playback position: ${state.positionData!.position}',
        );
      }

      return json;
    } catch (e) {
      logger.d('Error in toJson: $e');
      // Return minimal state if serialization fails
      return {'volume': state.volume, 'speed': state.speed};
    }
  }
}
