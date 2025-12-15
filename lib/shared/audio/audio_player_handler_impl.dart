import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/language_config.dart';
import '../../core/entities/moshaf_entity.dart';
import '../../core/entities/reciter_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/surah_names.dart';
import '../../features/reciters/domain/repositories/reciters_repository.dart';
import '../../main.dart';
import '../models/queue_state.dart';
import 'audio_player_handler.dart';

class AudioPlayerHandlerImpl extends BaseAudioHandler
    with SeekHandler
    implements AudioPlayerHandler {
  AudioPlayerHandlerImpl(
    this.newList,
    this._analyticsService,
    this._prefs,
    this._recitersRepository,
  ) {
    _init();
  }
  final BehaviorSubject<List<MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<MediaItem>[]);
  final List<MediaItem> newList;
  final AnalyticsService _analyticsService;
  final SharedPreferencesAsync _prefs;
  final RecitersRepository _recitersRepository;
  final _items = <String, List<MediaItem>>{};
  final _player = AudioPlayer();
  final List<AudioSource> _playlist = [];
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  // Caching and pagination
  List<MediaItem>? _cachedMediaItems;

  final Map<String, List<MediaItem>> _artistPlaylists = {};
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
              if (sequence == null) {
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
      Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>, QueueState>(
        queue,
        playbackState,
        _player.shuffleIndicesStream.whereType<List<int>>(),
        (queue, playbackState, shuffleIndices) => QueueState(
          queue: queue,
          queueIndex: playbackState.queueIndex,
          shuffleIndices:
              playbackState.shuffleMode == AudioServiceShuffleMode.all
              ? shuffleIndices
              : null,
          repeatMode: playbackState.repeatMode,
        ),
      ).where(
        (state) =>
            state.shuffleIndices == null ||
            state.queue.length == state.shuffleIndices!.length,
      );

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) {
      await _player.shuffle();
    }
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
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
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    speed.debounceTime(const Duration(milliseconds: 250)).listen((speed) {
      playbackState.add(playbackState.value.copyWith(speed: speed));
    });

    await updateQueue(newList);

    mediaItem.whereType<MediaItem>().listen(
      (item) => _recentSubject.add([item]),
    );

    Rx.combineLatest5<
          int?,
          List<MediaItem>,
          bool,
          List<int>?,
          Duration?,
          MediaItem?
        >(
          _player.currentIndexStream,
          queue,
          _player.shuffleModeEnabledStream,
          _player.shuffleIndicesStream,
          _player.durationStream,
          (index, queue, shuffleModeEnabled, shuffleIndices, duration) {
            final int? queueIndex = getQueueIndex(
              index,
              shuffleModeEnabled,
              shuffleIndices,
            );
            return (queueIndex != null && queueIndex < queue.length)
                ? queue[queueIndex].copyWith(duration: duration)
                : null;
          },
        )
        .whereType<MediaItem>()
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

    await _effectiveSequence
        .map(
          (sequence) =>
              sequence.map((source) => _mediaItemExpando[source]!).toList(),
        )
        .pipe(queue);

    _playlist.addAll(queue.value.map(_itemToSource).toList());
    await _safeSetAudioSources(_playlist);
  }

  AudioSource _itemToSource(MediaItem mediaItem) {
    final UriAudioSource audioSource = AudioSource.uri(Uri.parse(mediaItem.id));
    _mediaItemExpando[audioSource] = mediaItem;
    return audioSource;
  }

  List<AudioSource> _itemsToSources(List<MediaItem> mediaItems) =>
      mediaItems.map(_itemToSource).toList();

  /// Safely sets audio sources with proper error handling
  Future<void> _safeSetAudioSources(
    List<AudioSource> sources, {
    int initialIndex = 0,
  }) async {
    if (_isLoadingAudio) {
      log('Audio is already loading, skipping...');
      return;
    }

    _isLoadingAudio = true;

    try {
      // Stop current playback to prevent interruption
      await _player.stop();

      // Set new audio sources
      await _player.setAudioSources(sources, initialIndex: initialIndex);

      log('Successfully set ${sources.length} audio sources');
    } catch (e) {
      log('Error setting audio sources: $e');
      rethrow;
    } finally {
      _isLoadingAudio = false;
    }
  }

  /// Clears the audio player state and resets loading flags
  @override
  Future<void> clearAudioState() async {
    try {
      _isLoadingAudio = false;
      _currentLoadingArtist = null;
      await _player.stop();
      _playlist.clear();
      log('Audio state cleared');
    } catch (e) {
      log('Error clearing audio state: $e');
    }
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    return _items[parentMediaId] ?? [];
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        final Stream<Map<String, dynamic>> stream = _recentSubject.map(
          (_) => <String, dynamic>{},
        );
        return _recentSubject.hasValue
            ? stream.shareValueSeeded(<String, dynamic>{})
            : stream.shareValue();
      default:
        // return Stream.value(_mediaLibrary.items[parentMediaId])
        //     .map((_) => <String, dynamic>{})
        //     .shareValue();
        return super.subscribeToChildren(parentMediaId);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _playlist.add(_itemToSource(mediaItem));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    _playlist.addAll(_itemsToSources(mediaItems));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    _playlist.insert(index, _itemToSource(mediaItem));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    _playlist.clear();
    _playlist.addAll(_itemsToSources(queue));
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    final int index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[_player.sequence[index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final int index = queue.value.indexOf(mediaItem);
    _playlist.removeAt(index);
    await _safeSetAudioSources(_playlist);
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
    await _player.play();
    // Log analytics event
    final MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioPlay(
        currentItem.id,
        audioName: currentItem.title,
        artist: currentItem.artist,
      );
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // Log analytics event
    final MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioPause(currentItem.id);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    // Log analytics event
    final MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioSeek(currentItem.id, position.inSeconds);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // Log analytics event
    final MediaItem? currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioStop(currentItem.id);
    }
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
  }

  void _broadcastState(PlaybackEvent event) {
    final bool playing = _player.playing;
    final int? queueIndex = getQueueIndex(
      event.currentIndex,
      _player.shuffleModeEnabled,
      _player.shuffleIndices,
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
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
  Future<List<MediaItem>?> getReciters({String? languageCode}) async {
    // Return cached data if available
    if (_cachedMediaItems != null) {
      return _cachedMediaItems;
    }

    // Prevent multiple simultaneous requests
    if (_isLoadingReciters) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _cachedMediaItems;
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
          final mediaItems = <MediaItem>[];
          for (final reciter in reciters) {
            for (final MoshafEntity moshaf in reciter.moshaf) {
              final List<String> surahList = moshaf.surahList.split(',');
              for (final surahId in surahList) {
                final String formattedSurahId = surahId.padLeft(3, '0');
                final mediaItemId = '${moshaf.server}$formattedSurahId.mp3';
                // Note: Using SurahNames helper here might be async if you wanted strict localization check
                // but since title construction usually needs context or prefs
                // we can accept a slight delay or use the helper
                // Wait, SurahNames is sync.
                // But we might want localized names. The previous impl fetched reciters with lang code.
                // Our repo handles lang internally?
                // The repository fetches data based on prefs internally.

                mediaItems.add(
                  MediaItem(
                    id: mediaItemId,
                    title:
                        '${SurahNames.getEnglishSurahName(int.parse(surahId))} $formattedSurahId', // Fallback or standard
                    album: moshaf.name,
                    artist: reciter.name,
                  ),
                );
              }
            }
          }
          _cachedMediaItems = mediaItems;
          // _cachedRecitersEntities = reciters;
          return mediaItems;
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
      log('Error getting reciters data: ${failure.message}');
      return null;
    }, (reciters) => reciters);
  }

  // Helper to removed: _fetchReciters

  /// Get surah list for a specific moshaf
  @override
  Future<List<MediaItem>?> getSurahListForMoshaf(
    MoshafEntity moshaf, {
    String? reciterName,
  }) async {
    try {
      final List<String> surahList = moshaf.surahList.split(',');
      final mediaItems = <MediaItem>[];

      for (final surahId in surahList) {
        final int surahNumber = int.parse(surahId);
        final String formattedSurahId = surahId.padLeft(3, '0');
        final mediaItemId = '${moshaf.server}$formattedSurahId.mp3';
        final String surahName = await _getSurahName(surahNumber);

        mediaItems.add(
          MediaItem(
            id: mediaItemId,
            title: '$formattedSurahId - $surahName',
            album: moshaf.name,
            artist: reciterName ?? '', // Set reciter name if provided
            duration: const Duration(minutes: 5), // Default duration
          ),
        );
      }

      return mediaItems;
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
        final List<MediaItem> artistPlaylist = _artistPlaylists[artistId]!;
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
      final List<MediaItem>? reciters = await getReciters();

      if (reciters != null) {
        // Filter the reciters list to find the media items belonging to the artist with the provided artistId
        final List<MediaItem> artistPlaylist = reciters
            .where((item) => item.artist == artistId)
            .toList();

        if (artistPlaylist.isNotEmpty) {
          log('Found ${artistPlaylist.length} items for artist: $artistId');

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
      rethrow;
    } finally {
      _currentLoadingArtist = null;
    }
  }

  @override
  Future<void> playFromQueue(List<MediaItem> queue, int index) async {
    _playlist.clear();
    _playlist.addAll(_itemsToSources(queue));
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
