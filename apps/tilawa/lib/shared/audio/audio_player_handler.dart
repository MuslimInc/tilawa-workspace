import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../features/reciters/domain/repositories/reciters_repository.dart';
import '../models/queue_state.dart';

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  ValueStream<double> get volume;
  ValueStream<double> get speed;

  @override
  ValueStream<MediaItem?> get mediaItem;
  @override
  ValueStream<PlaybackState> get playbackState;
  @override
  ValueStream<List<MediaItem>> get queue;

  // Queue management methods
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  @override
  Future<void> addQueueItem(MediaItem mediaItem);
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems);
  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem);
  @override
  Future<void> updateQueue(List<MediaItem> queue);
  @override
  Future<void> updateMediaItem(MediaItem mediaItem);
  @override
  Future<void> removeQueueItem(MediaItem mediaItem);

  // Playback control methods
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode);
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode);
  @override
  Future<void> setSpeed(double speed);
  Future<void> setVolume(double volume);
  @override
  Future<void> skipToNext();
  @override
  Future<void> skipToPrevious();
  @override
  Future<void> skipToQueueItem(int index);
  @override
  Future<void> play();
  @override
  Future<void> pause();
  @override
  Future<void> seek(Duration position);
  @override
  Future<void> stop();

  // Audio state management
  Future<void> clearAudioState();
  Future<void> loadAudioPlayerData({bool restorePlayback = true});

  // Reciter and surah management
  Future<List<AudioEntity>?> getReciters({String? languageCode});
  Future<List<ReciterEntity>?> getRecitersData({String? languageCode});
  Future<ReciterEntity?> findReciterByName(
    String name, {
    String? languageCode,
  });
  Future<List<AudioEntity>?> getSurahListForMoshaf(
    MoshafEntity moshaf, {
    String? reciterName,
    String? reciterId,
  });
  Future<void> playArtistPlaylist(String artistId);
  Future<void> playFromQueue(
    List<MediaItem> queue,
    int index, {
    Duration? initialPosition,
  });

  // Children management (from AudioHandler)
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]);
  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId);

  /// Set reciters repository (used for testing)
  void setRecitersRepository(RecitersRepository repository);
}
