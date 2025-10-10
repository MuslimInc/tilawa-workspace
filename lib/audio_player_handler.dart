import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:muzakri/queue_state.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:rxdart/rxdart.dart';

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  ValueStream<double> get volume;
  ValueStream<double> get speed;

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

  // Reciter and surah management
  Future<List<MediaItem>?> getReciters();
  Future<List<Reciter>?> getRecitersData();
  Future<List<MediaItem>?> getSurahListForMoshaf(
    Mosahf moshaf, {
    String? reciterName,
  });
  Future<void> playArtistPlaylist(String artistId);

  // Children management (from AudioHandler)
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]);
  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId);
}
