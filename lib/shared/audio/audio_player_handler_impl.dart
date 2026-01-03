import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:audio_session/audio_session.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/language_config.dart';
import '../../core/entities/audio.dart';
import '../../core/entities/moshaf_entity.dart';
import '../../core/entities/reciter_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/surah_names.dart';
import '../../core/utils/url_validator.dart';
import '../../features/audio_player/domain/entities/audio_modes.dart';
import '../../features/downloads/domain/repositories/downloads_repository.dart';
import '../../features/reciters/domain/repositories/reciters_repository.dart';
import '../../main.dart';
import '../models/queue_state.dart';
import 'audio_player_handler.dart';

class AudioPlayerHandlerImpl extends audio_service.BaseAudioHandler
    with audio_service.SeekHandler
    implements AudioPlayerHandler {
  AudioPlayerHandlerImpl(
    this.newList,
    this._analyticsService,
    this._prefs,
    this._recitersRepository,
    this._downloadsRepository, {
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
  final SharedPreferencesAsync _prefs;
  final RecitersRepository _recitersRepository;
  final DownloadsRepository _downloadsRepository;
  final _items = <String, List<audio_service.MediaItem>>{};
  final AudioPlayer _player;
  final List<AudioSource> _playlist = [];
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemMap = <String, audio_service.MediaItem>{};

  // Caching and pagination

  final Map<String, List<audio_service.MediaItem>> _artistPlaylists = {};
  bool _isLoadingReciters = false;

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
            final int? rawIndex = _isLoadingAudio && _pendingIndex != null
                ? _pendingIndex
                : index;
            final int? queueIndex = getQueueIndex(
              rawIndex,
              shuffleModeEnabled,
              shuffleIndices,
            );
            return (queueIndex != null && queueIndex < queue.length)
                ? queue[queueIndex].copyWith(duration: duration)
                : null;
          },
        )
        .whereType<audio_service.MediaItem>()
        .listen(mediaItem.add);

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
    _playlist.addAll(initialSources);

    // Only set sources if we actually have items to avoid a default "index 0" jump
    if (_playlist.isNotEmpty) {
      await _safeSetAudioSources(_playlist);
    }
  }

  Future<AudioSource> _itemToSource(audio_service.MediaItem mediaItem) async {
    // Extract reciter name and URL from mediaItem
    final String? reciterName = mediaItem.artist;
    final String url = mediaItem.extras?['url'] ?? mediaItem.id;

    // Validate URL before proceeding
    if (!UrlValidator.isValid(url)) {
      log('Invalid audio URL for ${mediaItem.title}: $url');
      throw ArgumentError('Invalid audio URL: $url');
    }

    // Check if the surah is downloaded locally
    String? localFilePath;
    if (reciterName != null) {
      try {
        localFilePath = await _downloadsRepository.getDownloadedFilePath(
          url,
          reciterName,
        );
      } catch (e) {
        log('Error checking for downloaded file: $e');
      }
    }

    // Use local file if available, otherwise use network URL
    final Uri audioUri;
    try {
      audioUri = localFilePath != null
          ? Uri.file(localFilePath)
          : Uri.parse(url);
    } catch (e) {
      log('Error parsing audio URI for ${mediaItem.title}: $e');
      throw ArgumentError('Failed to parse audio URI: $url');
    }

    log(
      'Loading audio: ${mediaItem.title} from ${localFilePath != null ? "local file" : "network"}: $audioUri',
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
      await _player.setAudioSources(sources, initialIndex: initialIndex);

      log(
        'Successfully set ${sources.length} audio sources at index $initialIndex',
      );
    } catch (e, stackTrace) {
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
      _playlist.clear();
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
    _playlist.add(await _itemToSource(mediaItem));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> addQueueItems(List<audio_service.MediaItem> mediaItems) async {
    _playlist.addAll(await _itemsToSources(mediaItems));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> insertQueueItem(
    int index,
    audio_service.MediaItem mediaItem,
  ) async {
    _playlist.insert(index, await _itemToSource(mediaItem));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> updateQueue(List<audio_service.MediaItem> queue) async {
    _playlist.clear();
    _playlist.addAll(await _itemsToSources(queue));
    await _safeSetAudioSources(_playlist);
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
    final int index = _playlist.indexWhere((s) {
      // Safe check for tag
      if (s is UriAudioSource) {
        return s.tag == mediaItem.id;
      }
      return false;
    });

    if (index != -1) {
      _playlist.removeAt(index);
      _mediaItemMap.remove(mediaItem.id);
      await _safeSetAudioSources(_playlist);
    }
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    final AudioSource item = _playlist.removeAt(currentIndex);
    _playlist.insert(newIndex, item);
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> skipToNext() async {
    final int? currentIndex = _player.currentIndex;
    logger.d(
      '[AudioPlayerHandler] skipToNext: currentIndex=$currentIndex, playlistLength=${_playlist.length}',
    );
    if (currentIndex != null && currentIndex < _playlist.length - 1) {
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
      '[AudioPlayerHandler] skipToPrevious: currentIndex=$currentIndex, playlistLength=${_playlist.length}',
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
    if (index < 0 || index >= _playlist.length) {
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

  List<AudioEntity>? _cachedReciters;
  final Duration _cacheDuration = const Duration(minutes: 5);
  DateTime? _lastCacheTime;

  @override
  Future<List<AudioEntity>?> getReciters({String? languageCode}) async {
    // Return cached data if valid
    if (_cachedReciters != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedReciters;
    }

    // Prevent multiple simultaneous requests
    if (_isLoadingReciters) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _cachedReciters; // Return validation attempt or null
    }

    _isLoadingReciters = true;

    try {
      final Either<Failure, List<ReciterEntity>> recitersData =
          await _recitersRepository.getReciters();

      return recitersData.fold(
        (failure) {
          log('Error fetching reciters: ${failure.message}');
          return null;
        },
        (reciters) {
          final audioEntities = <AudioEntity>[];
          for (final reciter in reciters) {
            for (final MoshafEntity moshaf in reciter.moshaf) {
              final List<String> surahList = moshaf.surahList.split(',');
              for (final surahId in surahList) {
                final String formattedSurahId = surahId.padLeft(3, '0');
                final audioId = '${moshaf.server}$formattedSurahId.mp3';

                // Validate the constructed URL
                if (!UrlValidator.isValid(audioId)) {
                  log(
                    'Skipping invalid audio URL: $audioId for surah $surahId',
                  );
                  continue; // Skip this entry
                }

                audioEntities.add(
                  AudioEntity(
                    id: audioId,
                    title:
                        '${SurahNames.getEnglishSurahName(int.parse(surahId))} $formattedSurahId',
                    url: audioId,
                    duration: Duration.zero,
                    album: moshaf.name,
                    artist: reciter.name,
                  ),
                );
              }
            }
          }
          _cachedReciters = audioEntities;
          _lastCacheTime = DateTime.now();
          return audioEntities;
        },
      );
    } finally {
      _isLoadingReciters = false;
    }
  }

  /// Get raw reciters data for the RecitersScreen
  @override
  Future<List<ReciterEntity>?> getRecitersData({String? languageCode}) async {
    final Either<Failure, List<ReciterEntity>> result =
        await _recitersRepository.getReciters();
    return result.fold((failure) {
      return null;
    }, (reciters) => reciters);
  }

  // Helper to removed: _fetchReciters

  /// Get surah list for a specific moshaf
  @override
  Future<List<AudioEntity>?> getSurahListForMoshaf(
    MoshafEntity moshaf, {
    String? reciterName,
  }) async {
    try {
      final List<String> surahList = moshaf.surahList.split(',');
      final audioEntities = <AudioEntity>[];

      for (final surahId in surahList) {
        final int surahNumber = int.parse(surahId);
        final String formattedSurahId = surahId.padLeft(3, '0');
        final audioId = '${moshaf.server}$formattedSurahId.mp3';

        // Validate the constructed URL
        if (!UrlValidator.isValid(audioId)) {
          log('Skipping invalid audio URL: $audioId for surah $surahId');
          continue; // Skip this entry
        }

        final String surahName = await _getSurahName(surahNumber);

        audioEntities.add(
          AudioEntity(
            id: audioId,
            title: surahName,
            url: audioId,
            duration: Duration.zero,
            artist: reciterName,
            album: moshaf.name,
          ),
        );
      }

      return audioEntities;
    } catch (e) {
      log('Exception getting surah list: $e');
      return null;
    }
  }

  /// Get surah name by surah number based on selected language
  Future<String> _getSurahName(int surahNumber) async {
    final String currentLanguage =
        await _prefs.getString(LanguageConfig.languageKey) ??
        LanguageConfig.getDefaultLanguageCode();

    if (currentLanguage == 'en') {
      return SurahNames.getEnglishSurahName(surahNumber);
    } else {
      return SurahNames.getArabicSurahName(surahNumber);
    }
  }

  // Removed _getArabicSurahName and _getEnglishSurahName
  // They are now in SurahNames helper

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
      if (_artistPlaylists.containsKey(artistId)) {
        final List<audio_service.MediaItem> artistPlaylist =
            _artistPlaylists[artistId]!;
        log(
          'Using cached playlist for artist: $artistId (${artistPlaylist.length} items)',
        );

        await updateQueue(artistPlaylist);
        await skipToQueueItem(0);
        await play();
        return;
      }

      log('Loading playlist for artist: $artistId');

      // Fetch the reciters list from getReciters method
      final List<AudioEntity>? reciters = await getReciters();

      if (reciters != null) {
        // Filter the reciters list to find the items belonging to the artist
        final List<AudioEntity> artistAudioEntities = reciters
            .where((item) => item.artist == artistId)
            .toList();

        if (artistAudioEntities.isNotEmpty) {
          log(
            'Found ${artistAudioEntities.length} items for artist: $artistId',
          );

          final List<audio_service.MediaItem> artistPlaylist =
              artistAudioEntities.map(_mapAudioEntityToMediaItem).toList();

          // Cache the artist's playlist
          _artistPlaylists[artistId] = artistPlaylist;

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

  audio_service.MediaItem _mapAudioEntityToMediaItem(AudioEntity entity) {
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

  @override
  Future<void> playFromQueue(
    List<audio_service.MediaItem> queue,
    int index,
  ) async {
    _playlist.clear();
    _playlist.addAll(await _itemsToSources(queue));
    await _safeSetAudioSources(_playlist, initialIndex: index);
    await play();
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
