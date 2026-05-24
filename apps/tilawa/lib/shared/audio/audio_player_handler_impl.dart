import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import '../../features/audio_player/domain/entities/audio_modes.dart';
import '../../features/audio_player/domain/entities/reciter_audio_catalog.dart';
import '../../features/audio_player/domain/services/artist_media_playlist_cache.dart';
import '../../features/audio_player/domain/services/audio_entity_media_item_mapper.dart';
import '../../features/audio_player/domain/services/moshaf_surah_audio_list_builder.dart';
import '../../features/audio_player/domain/services/playback_uri_resolver.dart';
import '../../features/audio_player/domain/services/reciter_audio_catalog_cache.dart';
import '../../features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import '../models/queue_state.dart';
import 'audio_player_handler.dart';

class AudioPlayerHandlerImpl extends audio_service.BaseAudioHandler
    with audio_service.SeekHandler
    implements AudioPlayerHandler {
  AudioPlayerHandlerImpl(
    this.newList,
    this._analyticsService,
    this._catalogCache,
    this._playbackUriResolver,
    this._moshafSurahAudioListBuilder,
    this._artistMediaPlaylistCache,
    this._mediaItemMapper, {
    AudioPlayer? player,
    AudioSession? audioSession, // For testing
  }) : _player = player ?? AudioPlayer(),
       _testSession = audioSession {
    _init();
  }

  final AudioSession? _testSession;
  final BehaviorSubject<List<audio_service.MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<audio_service.MediaItem>[]);
  final List<audio_service.MediaItem> newList;
  final AnalyticsService _analyticsService;
  final ReciterAudioCatalogCache _catalogCache;
  final PlaybackUriResolver _playbackUriResolver;
  final MoshafSurahAudioListBuilder _moshafSurahAudioListBuilder;
  final ArtistMediaPlaylistCache _artistMediaPlaylistCache;
  final AudioEntityMediaItemMapper _mediaItemMapper;
  final _items = <String, List<audio_service.MediaItem>>{};
  final AudioPlayer _player;
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemMap = <String, audio_service.MediaItem>{};

  // Caching and pagination

  // Audio loading management
  bool _isLoadingAudio = false;
  String? _currentLoadingArtist;

  Stream<List<IndexedAudioSource>> get _effectiveSequence =>
      Rx.combineLatest3<
            List<IndexedAudioSource>?,
            List<int>?,
            bool,
            List<IndexedAudioSource>?
          >(
            _player.sequenceStream,
            _player.shuffleIndicesStream,
            _player.shuffleModeEnabledStream,
            (sequence, shuffleIndices, shuffleModeEnabled) {
              if (sequence == null || sequence.isEmpty) {
                return [];
              }
              if (!shuffleModeEnabled) {
                return sequence;
              }
              if (shuffleIndices == null) {
                return null;
              }
              if (shuffleIndices.length != sequence.length) {
                return null;
              }
              return shuffleIndices.map((i) => sequence[i]).toList();
            },
          )
          .whereType<List<IndexedAudioSource>>();

  int? getQueueIndex(
    int? currentIndex,
    bool shuffleModeEnabled,
    List<int>? shuffleIndices,
  ) {
    final List<int> effectiveIndices = _player.effectiveIndices;
    final List<int> shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }
    return (shuffleModeEnabled &&
            ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  @override
  Stream<QueueState> get queueState =>
      Rx.combineLatest3<
            List<audio_service.MediaItem>,
            audio_service.PlaybackState,
            List<int>,
            QueueState
          >(
            queue,
            playbackState,
            _player.shuffleIndicesStream.whereType<List<int>>(),
            (queue, playbackState, shuffleIndices) => QueueState(
              queue: queue.map(_mapMediaItemToAudioEntity).toList(),
              queueIndex: playbackState.queueIndex,
              shuffleIndices:
                  playbackState.shuffleMode ==
                      audio_service.AudioServiceShuffleMode.all
                  ? shuffleIndices
                  : null,
              repeatMode: _mapRepeatMode(playbackState.repeatMode),
            ),
          )
          .where(
            (state) =>
                state.shuffleIndices == null ||
                state.queue.length == state.shuffleIndices!.length,
          );

  AudioEntity _mapMediaItemToAudioEntity(audio_service.MediaItem item) {
    return AudioEntity(
      id: item.id,
      title: item.title,
      url: item.extras?['url'] ?? item.id,
      duration: item.duration ?? Duration.zero,
      artist: item.artist,
      album: item.album,
      artUri: item.artUri?.toString(),
      extras: item.extras,
    );
  }

  AudioRepeatMode _mapRepeatMode(audio_service.AudioServiceRepeatMode mode) {
    return switch (mode) {
      audio_service.AudioServiceRepeatMode.none => AudioRepeatMode.none,
      audio_service.AudioServiceRepeatMode.one => AudioRepeatMode.one,
      audio_service.AudioServiceRepeatMode.all => AudioRepeatMode.all,
      audio_service.AudioServiceRepeatMode.group => AudioRepeatMode.all,
    };
  }

  @override
  Future<void> loadAudioPlayerData({bool restorePlayback = true}) async {
    // Implementation for loading audio player data (e.g. from local storage)
    // This was previously handled by HydratedBloc, but now moved to UseCase/Repository/Handler
    log('Loading audio player data (restorePlayback: $restorePlayback)');
    // Add logic here if needed to restore state from SharedPreferences or similar
  }

  @override
  Future<void> setShuffleMode(
    audio_service.AudioServiceShuffleMode shuffleMode,
  ) async {
    final enabled = shuffleMode == audio_service.AudioServiceShuffleMode.all;
    if (enabled) {
      await _player.shuffle();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(
    audio_service.AudioServiceRepeatMode repeatMode,
  ) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.add(speed);
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume.add(volume);
    await _player.setVolume(volume);
  }

  Future<void> _init() async {
    try {
      final AudioSession session = _testSession ?? await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (e) {
      log('AudioSession initialization failed: $e');
    }

    speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
      playbackState.add(playbackState.value.copyWith(speed: speed));
    });

    await updateQueue(newList);

    mediaItem.whereType<audio_service.MediaItem>().listen(
      (item) => _recentSubject.add([item]),
    );

    Rx.combineLatest5<
          int?,
          List<audio_service.MediaItem>,
          bool,
          List<int>?,
          Duration?,
          audio_service.MediaItem?
        >(
          _player.currentIndexStream,
          queue,
          _player.shuffleModeEnabledStream,
          _player.shuffleIndicesStream,
          _player.durationStream,
          (index, queue, shuffleModeEnabled, shuffleIndices, duration) {
            // This prevents applying the next track's duration to the previous track.
            final int? currentIndex = _player.currentIndex;

            final int? rawIndex = _isLoadingAudio && _pendingIndex != null
                ? _pendingIndex
                : (currentIndex ?? index);
            final int? queueIndex = getQueueIndex(
              rawIndex,
              shuffleModeEnabled,
              shuffleIndices,
            );

            final result = (queueIndex != null && queueIndex < queue.length)
                ? queue[queueIndex].copyWith(duration: duration)
                : null;

            return result;
          },
        )
        .whereType<audio_service.MediaItem>()
        .distinct((prev, next) => prev.toString() == next.toString())
        .listen((item) {
          mediaItem.add(item);
          // Only update the queue if the duration has actually changed
          // to avoid infinite recursive loops.
          if (_mediaItemMap[item.id]?.duration != item.duration) {
            updateMediaItem(item);
          }
        });

    _player.playbackEventStream.listen(_broadcastState);
    _player.shuffleModeEnabledStream.listen(
      (enabled) => _broadcastState(_player.playbackEvent),
    );

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
        _player.seek(Duration.zero, index: 0);
      }
    });

    _effectiveSequence
        .map(
          (sequence) => sequence
              .map((source) => _mediaItemMap[source.tag])
              .whereType<audio_service.MediaItem>()
              .toList(),
        )
        .listen(queue.add);

    final List<AudioSource> initialSources = await Future.wait(
      queue.value.map(_itemToSource),
    );

    // Only set sources if we actually have items to avoid a default "index 0" jump
    if (initialSources.isNotEmpty) {
      await _safeSetAudioSources(initialSources);
    }
  }

  int _indexOfAudioSourceWithTag(String mediaId) {
    final List<AudioSource> sources = _player.audioSources;
    for (var i = 0; i < sources.length; i++) {
      final AudioSource s = sources[i];
      if (s is UriAudioSource && s.tag == mediaId) {
        return i;
      }
    }
    return -1;
  }

  Future<AudioSource> _itemToSource(audio_service.MediaItem mediaItem) async {
    // Extract reciter name and URL from mediaItem
    final String? reciterName = mediaItem.artist;
    final String url = mediaItem.extras?['url'] ?? mediaItem.id;

    final Uri audioUri = await _playbackUriResolver.resolve(
      url: url,
      reciterName: reciterName,
    );

    log(
      'Loading audio: ${mediaItem.title} from '
      '${audioUri.scheme == "file" ? "local file" : "network"}: $audioUri',
    );

    final UriAudioSource audioSource = AudioSource.uri(
      audioUri,
      tag: mediaItem.id,
    );
    _mediaItemMap[mediaItem.id] = mediaItem;
    return audioSource;
  }

  Future<List<AudioSource>> _itemsToSources(
    List<audio_service.MediaItem> mediaItems,
  ) async {
    return Future.wait(mediaItems.map(_itemToSource));
  }

  int? _pendingIndex;

  Future<void> _safeSetAudioSources(
    List<AudioSource> sources, {
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    // TRACKING: We want to allow new requests to override old ones
    // just_audio handles concurrency internally for setAudioSource

    _isLoadingAudio = true;
    // If sources are empty, index should be null
    final int? effectiveIndex = initialIndex ?? (sources.isEmpty ? null : 0);
    _pendingIndex = effectiveIndex;

    // IMMEDIATE FEEDBACK: Manually broadcast the target index so UI stays in sync
    // before the player even finishes loading.
    playbackState.add(
      playbackState.value.copyWith(
        processingState: audio_service.AudioProcessingState.loading,
        queueIndex: effectiveIndex,
      ),
    );

    try {
      // NOTE: We used to call _player.stop() here, but it's unnecessary
      // and can cause extra state flickers. just_audio handles it.

      // Validate all sources before attempting to set
      if (sources.isEmpty) {
        log('Warning: Attempting to set empty audio sources');
      }

      // Set new audio sources
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
      );

      log(
        'Successfully set ${sources.length} audio sources at index $initialIndex',
      );
    } catch (e, stackTrace) {
      // Check for just_audio interruption or abortion
      bool isInterrupted =
          e.toString().contains('Loading interrupted') ||
          e.toString().contains('aborted');

      if (e is PlatformException && e.code == 'abort') {
        isInterrupted = true;
      }

      if (isInterrupted) {
        log('Loading interrupted as expected: $e');
        return;
      }
      log('Error setting audio sources: $e\n$stackTrace');
      // Broadcast error state
      playbackState.add(
        playbackState.value.copyWith(
          processingState: audio_service.AudioProcessingState.error,
        ),
      );
      rethrow;
    } finally {
      // Small delay to let the event stream stabilize with the new index
      Future.delayed(const Duration(milliseconds: 100), () {
        _isLoadingAudio = false;
        _pendingIndex = null;
      });
    }
  }

  /// Clears the audio player state and resets loading flags
  @override
  Future<void> clearAudioState() async {
    try {
      _isLoadingAudio = false;
      _currentLoadingArtist = null;
      _pendingIndex = null;
      await _player.stop();
      await _player.clearAudioSources();
      log('Audio state cleared');
    } catch (e) {
      log('Error clearing audio state: $e');
    }
  }

  @override
  Future<List<audio_service.MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    return _items[parentMediaId] ?? [];
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    switch (parentMediaId) {
      case '__RECENT__':
        return _recentSubject.map((_) => <String, dynamic>{}).shareValue();
      default:
        return super.subscribeToChildren(parentMediaId);
    }
  }

  @override
  Future<void> addQueueItem(audio_service.MediaItem mediaItem) async {
    await _player.addAudioSource(await _itemToSource(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<audio_service.MediaItem> mediaItems) async {
    await _player.addAudioSources(await _itemsToSources(mediaItems));
  }

  @override
  Future<void> insertQueueItem(
    int index,
    audio_service.MediaItem mediaItem,
  ) async {
    await _player.insertAudioSource(
      index,
      await _itemToSource(mediaItem),
    );
  }

  @override
  Future<void> updateQueue(List<audio_service.MediaItem> queue) async {
    final List<AudioSource> sources = await _itemsToSources(queue);
    await _safeSetAudioSources(sources);
  }

  @override
  Future<void> updateMediaItem(audio_service.MediaItem mediaItem) async {
    _mediaItemMap[mediaItem.id] = mediaItem;
    final List<audio_service.MediaItem> currentQueue = queue.value;
    final List<audio_service.MediaItem> newQueue = currentQueue
        .map((item) => item.id == mediaItem.id ? mediaItem : item)
        .toList();
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItem(audio_service.MediaItem mediaItem) async {
    final int index = _indexOfAudioSourceWithTag(mediaItem.id);

    if (index != -1) {
      await _player.removeAudioSourceAt(index);
      _mediaItemMap.remove(mediaItem.id);
    }
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _player.moveAudioSource(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() async {
    final int? currentIndex = _player.currentIndex;
    logger.d(
      '[AudioPlayerHandler] skipToNext: currentIndex=$currentIndex, playlistLength=${_player.audioSources.length}',
    );
    if (currentIndex != null &&
        currentIndex < _player.audioSources.length - 1) {
      logger.d(
        '[AudioPlayerHandler] skipToNext: moving to index ${currentIndex + 1}',
      );
      await skipToQueueItem(currentIndex + 1);
    } else {
      logger.d(
        '[AudioPlayerHandler] skipToNext: cannot skip - at end of playlist or no current index',
      );
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final int? currentIndex = _player.currentIndex;
    logger.d(
      '[AudioPlayerHandler] skipToPrevious: currentIndex=$currentIndex, playlistLength=${_player.audioSources.length}',
    );
    if (currentIndex != null && currentIndex > 0) {
      logger.d(
        '[AudioPlayerHandler] skipToPrevious: moving to index ${currentIndex - 1}',
      );
      await skipToQueueItem(currentIndex - 1);
    } else {
      logger.d(
        '[AudioPlayerHandler] skipToPrevious: cannot skip - at beginning of playlist or no current index',
      );
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _player.audioSources.length) {
      return;
    }

    await _player.seek(
      Duration.zero,
      index: _player.shuffleModeEnabled ? _player.shuffleIndices[index] : index,
    );
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
      // Log analytics event
      final audio_service.MediaItem? currentItem = mediaItem.valueOrNull;
      if (currentItem != null) {
        await _analyticsService.logAudioPlay(
          currentItem.id,
          audioName: currentItem.title,
          artist: currentItem.artist,
        );
      }
    } catch (e) {
      // Check for just_audio interruption or abortion
      bool isInterrupted =
          e.toString().contains('Loading interrupted') ||
          e.toString().contains('aborted');

      if (e is PlatformException && e.code == 'abort') {
        isInterrupted = true;
      }

      if (isInterrupted) {
        log('Play interrupted as expected: $e');
        return;
      }

      log('Error playing audio: $e');
      // Broadcast error state
      playbackState.add(
        playbackState.value.copyWith(
          processingState: audio_service.AudioProcessingState.error,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // Log analytics event
    final audio_service.MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioPause(currentItem.id);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    // Log analytics event
    final audio_service.MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioSeek(currentItem.id, position.inSeconds);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // Log analytics event
    final audio_service.MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioStop(currentItem.id);
    }
    await playbackState.firstWhere(
      (state) =>
          state.processingState == audio_service.AudioProcessingState.idle,
    );
  }

  void _broadcastState(PlaybackEvent event) {
    final bool playing = _player.playing;

    // USE PENDING INDEX: During loading transitions, use the target index
    // instead of the player's stale currentIndex.
    final int? rawIndex = _isLoadingAudio && _pendingIndex != null
        ? _pendingIndex
        : event.currentIndex;

    final int? queueIndex = getQueueIndex(
      rawIndex,
      _player.shuffleModeEnabled,
      _player.shuffleIndices,
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          audio_service.MediaControl.skipToPrevious,
          if (playing)
            audio_service.MediaControl.pause
          else
            audio_service.MediaControl.play,
          audio_service.MediaControl.stop,
          audio_service.MediaControl.skipToNext,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: audio_service.AudioProcessingState.idle,
          ProcessingState.loading: audio_service.AudioProcessingState.loading,
          ProcessingState.buffering:
              audio_service.AudioProcessingState.buffering,
          ProcessingState.ready: audio_service.AudioProcessingState.ready,
          ProcessingState.completed:
              audio_service.AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex,
      ),
    );
  }

  @override
  Future<List<AudioEntity>?> getReciters({String? languageCode}) async {
    return _catalogCache.loadTracks();
  }

  /// Get raw reciters data for the RecitersScreen
  @override
  Future<List<ReciterEntity>?> getRecitersData({String? languageCode}) async {
    return _catalogCache.loadReciters();
  }

  @override
  Future<ReciterEntity?> findReciterByName(
    String name, {
    String? languageCode,
  }) async {
    return _catalogCache.reciterNamed(name);
  }

  // Helper to removed: _fetchReciters

  /// Get surah list for a specific moshaf
  @override
  Future<List<AudioEntity>?> getSurahListForMoshaf(
    MoshafEntity moshaf, {
    String? reciterName,
    String? reciterId,
  }) {
    return _moshafSurahAudioListBuilder.build(
      moshaf,
      reciterName: reciterName,
      reciterId: reciterId,
    );
  }

  // Future<void> playArtistPlaylist(String artistId) async {
  //   final reciters = await getReciters();
  //   log("reciters: $reciters #");
  //   final artistPlaylist = _mediaLibrary.items[artistId];
  //   if (artistPlaylist != null) {
  //     await updateQueue(artistPlaylist);
  //     await skipToQueueItem(0);
  //     await play();
  //   }
  // }

  @override
  Future<void> playArtistPlaylist(String artistId) async {
    try {
      // Prevent multiple simultaneous calls for the same artist
      if (_currentLoadingArtist == artistId && _isLoadingAudio) {
        log('Already loading playlist for artist: $artistId');
        return;
      }

      _currentLoadingArtist = artistId;

      // Check if we already have this artist's playlist cached
      final List<audio_service.MediaItem>? cachedPlaylist =
          _artistMediaPlaylistCache.playlistFor(artistId);
      if (cachedPlaylist != null) {
        final List<audio_service.MediaItem> artistPlaylist = cachedPlaylist;
        log(
          'Using cached playlist for artist: $artistId (${artistPlaylist.length} items)',
        );

        await updateQueue(artistPlaylist);
        await skipToQueueItem(0);
        await play();
        return;
      }

      log('Loading playlist for artist: $artistId');

      final ReciterAudioCatalog? catalog = await _catalogCache.loadCatalog();

      if (catalog != null) {
        final List<AudioEntity> artistAudioEntities = catalog.tracksForArtist(
          artistId,
        );

        if (artistAudioEntities.isNotEmpty) {
          log(
            'Found ${artistAudioEntities.length} items for artist: $artistId',
          );

          final List<audio_service.MediaItem> artistPlaylist =
              artistAudioEntities.map(_mediaItemMapper.toMediaItem).toList();

          _artistMediaPlaylistCache.store(artistId, artistPlaylist);

          // Update the queue with the artist's playlist
          await updateQueue(artistPlaylist);

          // Skip to the first item in the queue
          await skipToQueueItem(0);

          // Start playing the playlist
          await play();
        } else {
          log('No playlist found for artist with id: $artistId');
        }
      } else {
        log('No reciters found.');
      }
    } catch (e) {
      log('Error playing artist playlist: $e');
    } finally {
      _currentLoadingArtist = null;
    }
  }

  @override
  Future<void> playFromQueue(
    List<audio_service.MediaItem> queue,
    int index, {
    Duration? initialPosition,
  }) async {
    await _safeSetAudioSources(
      await _itemsToSources(queue),
      initialIndex: index,
      initialPosition: initialPosition,
    );
    await play();
  }

  @override
  void setRecitersRepository(RecitersRepository repository) {
    _catalogCache.bindRepository(repository);
  }
}

extension SurahNameX on String {
  String get surahName {
    try {
      final int n = int.parse(this);
      // Assuming Arabic default for this random extension if context is unknown,
      // or we can use the helper which handles localization if we passed lang.
      // But this extension just returns the Arabic name prefixed.
      // Keeping original behavior:
      return SurahNames.getArabicSurahName(n);
    } catch (e) {
      return this;
    }
  }
}
