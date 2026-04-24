import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../../../shared/audio/audio_player_handler.dart';
import '../../../../shared/services/audio_position_service.dart';
import '../../domain/entities/audio_modes.dart';
import '../../domain/repositories/audio_player_repository.dart';

@LazySingleton(as: AudioPlayerRepository)
class AudioPlayerRepositoryImpl implements AudioPlayerRepository {
  AudioPlayerRepositoryImpl(this._audioHandler, this._positionService);

  final AudioPlayerHandler _audioHandler;
  final AudioPositionService _positionService;
  static const String _loadingInterruptedMessage = 'Loading interrupted';
  static const String _abortMessage = 'abort';

  bool _isLoadingInterrupted(Object error) {
    final String message = error.toString();
    return message.contains(_loadingInterruptedMessage) ||
        message.contains(_abortMessage);
  }

  ResultVoid _guardVoid(Future<void> Function() action) async {
    try {
      await action();
      return const Right(null);
    } catch (e) {
      if (_isLoadingInterrupted(e)) {
        return const Right(null);
      }
      return Left(AudioFailure(e.toString()));
    }
  }

  @override
  Stream<AudioEntity?> get currentAudio => _audioHandler.mediaItem
      .map((item) => item != null ? _mapMediaItemToEntity(item) : null)
      .distinct();

  @override
  Stream<PlaybackStateEntity> get playbackState =>
      Rx.combineLatest2<
            audio_service.PlaybackState,
            List<audio_service.MediaItem>,
            PlaybackStateEntity
          >(
            _audioHandler.playbackState,
            _audioHandler.queue,
            (state, queue) => PlaybackStateEntity(
              isPlaying: state.playing,
              processingState: _mapProcessingStateToEntity(
                state.processingState,
              ),
              position: state.position,
              bufferedPosition: state.bufferedPosition,
              duration:
                  _audioHandler.mediaItem.value?.duration ?? Duration.zero,
              currentIndex: state.queueIndex ?? 0,
              queue: queue.map(_mapMediaItemToEntity).toList(),
            ),
          )
          .distinct();

  @override
  Stream<Duration> get position => _positionService.position;

  @override
  Stream<List<AudioEntity>> get queue => _audioHandler.queue
      .map((items) => items.map(_mapMediaItemToEntity).toList())
      .distinct();

  @override
  Stream<double> get speed => _audioHandler.speed.distinct();

  @override
  Stream<double> get volume => _audioHandler.volume.distinct();

  @override
  PlaybackStateEntity get getPlaybackState {
    final audio_service.PlaybackState state = _audioHandler.playbackState.value;
    final List<audio_service.MediaItem> queue = _audioHandler.queue.value;
    return PlaybackStateEntity(
      isPlaying: state.playing,
      processingState: _mapProcessingStateToEntity(state.processingState),
      position: state.position,
      bufferedPosition: state.bufferedPosition,
      duration: _audioHandler.mediaItem.value?.duration ?? Duration.zero,
      currentIndex: state.queueIndex ?? 0,
      queue: queue.map(_mapMediaItemToEntity).toList(),
    );
  }

  @override
  ResultVoid play() async {
    return _guardVoid(_audioHandler.play);
  }

  @override
  ResultVoid pause() async {
    return _guardVoid(_audioHandler.pause);
  }

  @override
  ResultVoid stop() async {
    return _guardVoid(_audioHandler.stop);
  }

  @override
  ResultVoid seek(Duration position) async {
    return _guardVoid(() => _audioHandler.seek(position));
  }

  @override
  ResultVoid next() async {
    return _guardVoid(_audioHandler.skipToNext);
  }

  @override
  ResultVoid previous() async {
    return _guardVoid(_audioHandler.skipToPrevious);
  }

  @override
  ResultVoid skipToQueueItem(int index) async {
    return _guardVoid(() => _audioHandler.skipToQueueItem(index));
  }

  @override
  ResultVoid setVolume(double volume) async {
    return _guardVoid(() => _audioHandler.setVolume(volume));
  }

  @override
  ResultVoid setSpeed(double speed) async {
    return _guardVoid(() => _audioHandler.setSpeed(speed));
  }

  @override
  ResultVoid setRepeatMode(AudioRepeatMode repeatMode) async {
    return _guardVoid(
      () => _audioHandler.setRepeatMode(_mapRepeatModeToService(repeatMode)),
    );
  }

  @override
  ResultVoid setShuffleMode(AudioShuffleMode shuffleMode) async {
    return _guardVoid(
      () => _audioHandler.setShuffleMode(_mapShuffleModeToService(shuffleMode)),
    );
  }

  @override
  ResultVoid addQueueItem(AudioEntity audio) async {
    return _guardVoid(
      () => _audioHandler.addQueueItem(_mapEntityToMediaItem(audio)),
    );
  }

  @override
  ResultVoid removeQueueItem(AudioEntity audio) async {
    return _guardVoid(
      () => _audioHandler.removeQueueItem(_mapEntityToMediaItem(audio)),
    );
  }

  @override
  ResultVoid moveQueueItem(int currentIndex, int newIndex) async {
    return _guardVoid(
      () => _audioHandler.moveQueueItem(currentIndex, newIndex),
    );
  }

  @override
  ResultVoid updateQueue(List<AudioEntity> queue) async {
    return _guardVoid(
      () =>
          _audioHandler.updateQueue(queue.map(_mapEntityToMediaItem).toList()),
    );
  }

  @override
  ResultVoid playFromQueue(
    List<AudioEntity> queue,
    int index, {
    Duration? initialPosition,
  }) async {
    return _guardVoid(
      () => _audioHandler.playFromQueue(
        queue.map(_mapEntityToMediaItem).toList(),
        index,
        initialPosition: initialPosition,
      ),
    );
  }

  @override
  ResultVoid loadAudioPlayerData({bool restorePlayback = true}) async {
    return _guardVoid(
      () => _audioHandler.loadAudioPlayerData(restorePlayback: restorePlayback),
    );
  }

  // Mappers
  AudioProcessingStateStatus _mapProcessingStateToEntity(
    audio_service.AudioProcessingState serviceState,
  ) {
    return switch (serviceState) {
      audio_service.AudioProcessingState.idle =>
        AudioProcessingStateStatus.idle,
      audio_service.AudioProcessingState.loading =>
        AudioProcessingStateStatus.loading,
      audio_service.AudioProcessingState.buffering =>
        AudioProcessingStateStatus.buffering,
      audio_service.AudioProcessingState.ready =>
        AudioProcessingStateStatus.ready,
      audio_service.AudioProcessingState.completed =>
        AudioProcessingStateStatus.completed,
      audio_service.AudioProcessingState.error =>
        AudioProcessingStateStatus.error,
    };
  }

  AudioEntity _mapMediaItemToEntity(audio_service.MediaItem item) {
    return AudioEntity(
      id: item.id,
      title: item.title,
      url:
          item.extras?['url'] ??
          '', // Assuming URL is in extras or handled elsewhere
      duration: item.duration ?? Duration.zero,
      artist: item.artist,
      album: item.album,
      artUri: item.artUri?.toString(),
      extras: item.extras,
    );
  }

  audio_service.MediaItem _mapEntityToMediaItem(AudioEntity entity) {
    final Map<String, dynamic> extras = Map.of(entity.extras ?? {});
    extras['url'] = entity.url;

    return audio_service.MediaItem(
      id: entity.id,
      title: entity.title,
      duration: entity.duration,
      artist: entity.artist,
      album: entity.album,
      artUri: entity.artUri != null ? Uri.parse(entity.artUri!) : null,
      extras: extras,
    );
  }

  audio_service.AudioServiceRepeatMode _mapRepeatModeToService(
    AudioRepeatMode mode,
  ) {
    return switch (mode) {
      AudioRepeatMode.none => audio_service.AudioServiceRepeatMode.none,
      AudioRepeatMode.one => audio_service.AudioServiceRepeatMode.one,
      AudioRepeatMode.all => audio_service.AudioServiceRepeatMode.all,
    };
  }

  audio_service.AudioServiceShuffleMode _mapShuffleModeToService(
    AudioShuffleMode mode,
  ) {
    return switch (mode) {
      AudioShuffleMode.none => audio_service.AudioServiceShuffleMode.none,
      AudioShuffleMode.all => audio_service.AudioServiceShuffleMode.all,
    };
  }
}
