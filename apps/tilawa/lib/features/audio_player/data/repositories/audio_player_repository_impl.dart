import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'package:tilawa_core/entities/audio.dart';
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
    await _audioHandler.play();
    return const Right(null);
  }

  @override
  ResultVoid pause() async {
    await _audioHandler.pause();
    return const Right(null);
  }

  @override
  ResultVoid stop() async {
    await _audioHandler.stop();
    return const Right(null);
  }

  @override
  ResultVoid seek(Duration position) async {
    await _audioHandler.seek(position);
    return const Right(null);
  }

  @override
  ResultVoid next() async {
    await _audioHandler.skipToNext();
    return const Right(null);
  }

  @override
  ResultVoid previous() async {
    await _audioHandler.skipToPrevious();
    return const Right(null);
  }

  @override
  ResultVoid skipToQueueItem(int index) async {
    await _audioHandler.skipToQueueItem(index);
    return const Right(null);
  }

  @override
  ResultVoid setVolume(double volume) async {
    await _audioHandler.setVolume(volume);
    return const Right(null);
  }

  @override
  ResultVoid setSpeed(double speed) async {
    await _audioHandler.setSpeed(speed);
    return const Right(null);
  }

  @override
  ResultVoid setRepeatMode(AudioRepeatMode repeatMode) async {
    await _audioHandler.setRepeatMode(_mapRepeatModeToService(repeatMode));
    return const Right(null);
  }

  @override
  ResultVoid setShuffleMode(AudioShuffleMode shuffleMode) async {
    await _audioHandler.setShuffleMode(_mapShuffleModeToService(shuffleMode));
    return const Right(null);
  }

  @override
  ResultVoid addQueueItem(AudioEntity audio) async {
    await _audioHandler.addQueueItem(_mapEntityToMediaItem(audio));
    return const Right(null);
  }

  @override
  ResultVoid removeQueueItem(AudioEntity audio) async {
    await _audioHandler.removeQueueItem(_mapEntityToMediaItem(audio));
    return const Right(null);
  }

  @override
  ResultVoid moveQueueItem(int currentIndex, int newIndex) async {
    await _audioHandler.moveQueueItem(currentIndex, newIndex);
    return const Right(null);
  }

  @override
  ResultVoid updateQueue(List<AudioEntity> queue) async {
    await _audioHandler.updateQueue(queue.map(_mapEntityToMediaItem).toList());
    return const Right(null);
  }

  @override
  ResultVoid playFromQueue(List<AudioEntity> queue, int index) async {
    await _audioHandler.playFromQueue(
      queue.map(_mapEntityToMediaItem).toList(),
      index,
    );
    return const Right(null);
  }

  @override
  ResultVoid loadAudioPlayerData({bool restorePlayback = true}) async {
    await _audioHandler.loadAudioPlayerData(restorePlayback: restorePlayback);
    return const Right(null);
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
    );
  }

  audio_service.MediaItem _mapEntityToMediaItem(AudioEntity entity) {
    return audio_service.MediaItem(
      id: entity.id,
      title: entity.title,
      duration: entity.duration,
      artist: entity.artist,
      album: entity.album,
      artUri: entity.artUri != null ? Uri.parse(entity.artUri!) : null,
      extras: {'url': entity.url},
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
