import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/core/services/analytics_service.dart';
import 'package:muzakri/queue_state.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerHandlerImpl extends BaseAudioHandler
    with SeekHandler
    implements AudioPlayerHandler {
  AudioPlayerHandlerImpl(this.newList, this._analyticsService) {
    _init();
  }
  final BehaviorSubject<List<MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<MediaItem>[]);
  final List<MediaItem> newList;
  final AnalyticsService _analyticsService;
  final _items = <String, List<MediaItem>>{};
  final _player = AudioPlayer();
  final List<AudioSource> _playlist = [];
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();

  // Caching and pagination
  List<MediaItem>? _cachedReciters;
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
              if (sequence == null) return [];
              if (!shuffleModeEnabled) return sequence;
              if (shuffleIndices == null) return null;
              if (shuffleIndices.length != sequence.length) return null;
              return shuffleIndices.map((i) => sequence[i]).toList();
            },
          )
          .whereType<List<IndexedAudioSource>>();

  int? getQueueIndex(
    int? currentIndex,
    bool shuffleModeEnabled,
    List<int>? shuffleIndices,
  ) {
    final effectiveIndices = _player.effectiveIndices;
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
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
    final session = await AudioSession.instance;
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
            final queueIndex = getQueueIndex(
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

    _effectiveSequence
        .map(
          (sequence) =>
              sequence.map((source) => _mediaItemExpando[source]!).toList(),
        )
        .pipe(queue);

    _playlist.addAll(queue.value.map(_itemToSource).toList());
    await _safeSetAudioSources(_playlist);
  }

  AudioSource _itemToSource(MediaItem mediaItem) {
    final audioSource = AudioSource.uri(Uri.parse(mediaItem.id));
    _mediaItemExpando[audioSource] = mediaItem;
    return audioSource;
  }

  List<AudioSource> _itemsToSources(List<MediaItem> mediaItems) =>
      mediaItems.map(_itemToSource).toList();

  /// Safely sets audio sources with proper error handling
  Future<void> _safeSetAudioSources(List<AudioSource> sources) async {
    if (_isLoadingAudio) {
      log('Audio is already loading, skipping...');
      return;
    }

    _isLoadingAudio = true;

    try {
      // Stop current playback to prevent interruption
      await _player.stop();

      // Wait a bit to ensure the stop operation completes
      await Future.delayed(const Duration(milliseconds: 100));

      // Set new audio sources
      await _player.setAudioSources(sources);

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
        final stream = _recentSubject.map((_) => <String, dynamic>{});
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
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[_player.sequence[index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexOf(mediaItem);
    _playlist.removeAt(index);
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    final item = _playlist.removeAt(currentIndex);
    _playlist.insert(newIndex, item);
    await _safeSetAudioSources(_playlist);
  }

  @override
  Future<void> skipToNext() async {
    final currentIndex = _player.currentIndex;
    print(
      'skipToNext: currentIndex=$currentIndex, playlistLength=${_playlist.length}',
    );
    if (currentIndex != null && currentIndex < _playlist.length - 1) {
      print('skipToNext: moving to index ${currentIndex + 1}');
      await skipToQueueItem(currentIndex + 1);
    } else {
      print('skipToNext: cannot skip - at end of playlist or no current index');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _player.currentIndex;
    print(
      'skipToPrevious: currentIndex=$currentIndex, playlistLength=${_playlist.length}',
    );
    if (currentIndex != null && currentIndex > 0) {
      print('skipToPrevious: moving to index ${currentIndex - 1}');
      await skipToQueueItem(currentIndex - 1);
    } else {
      print(
        'skipToPrevious: cannot skip - at beginning of playlist or no current index',
      );
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _player.seek(
      Duration.zero,
      index: _player.shuffleModeEnabled ? _player.shuffleIndices[index] : index,
    );
  }

  @override
  Future<void> play() async {
    await _player.play();
    // Log analytics event
    final currentItem = mediaItem.valueOrNull;
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
    final currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioPause(currentItem.id);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    // Log analytics event
    final currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioSeek(currentItem.id, position.inSeconds);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    // Log analytics event
    final currentItem = mediaItem.valueOrNull;
    if (currentItem != null) {
      await _analyticsService.logAudioStop(currentItem.id);
    }
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex = getQueueIndex(
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

  // Future<List<MediaItem>?> getReciters() async {
  //   final baseUrl = "https://mp3quran.net/api/v3/reciters";
  //   try {
  //     final response = await Dio().get(baseUrl);

  //     if (response.statusCode == 200) {
  //       final map = response.data as Map<String, dynamic>;

  //       // Log the raw data
  //       log(map.toString());

  //       // Parse the JSON into the RecitersModel
  //       final recitersModel = RecitersModel.fromJson(map);

  //       // Convert Reciters to MediaItems (if needed)
  //       final mediaItems = recitersModel.reciters.map((reciter) {
  //         return MediaItem(
  //           id: reciter.id.toString(),
  //           title: reciter.name,
  //           album: reciter.moshaf.isNotEmpty
  //               ? reciter.moshaf.first.name
  //               : '', // Example of using the first moshaf name
  //           artist: reciter.name,
  //           // Add other MediaItem properties as needed
  //         );
  //       }).toList();

  //       return mediaItems;
  //     } else {
  //       log('Error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log('Exception: $e');
  //   }
  //   return null;
  // }

  @override
  Future<List<MediaItem>?> getReciters() async {
    // Return cached data if available
    if (_cachedReciters != null) {
      return _cachedReciters;
    }

    // Prevent multiple simultaneous requests
    if (_isLoadingReciters) {
      // Wait for the ongoing request to complete
      while (_isLoadingReciters) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedReciters;
    }

    _isLoadingReciters = true;
    final baseUrl = "https://mp3quran.net/api/v3/reciters";

    try {
      final response = await Dio().get(baseUrl);

      if (response.statusCode == 200) {
        final map = response.data as Map<String, dynamic>;

        // Parse the JSON into the RecitersModel
        final recitersModel = RecitersModel.fromJson(map);

        // Convert Reciters to MediaItems (if needed)
        final mediaItems = <MediaItem>[];

        // Iterate through each reciter and generate MediaItems for their surahs
        for (var reciter in recitersModel.reciters) {
          for (var moshaf in reciter.moshaf) {
            // Split the surah_list into individual surah IDs
            final surahList = moshaf.surahList.split(',');

            // Create MediaItem for each surah
            for (var surahId in surahList) {
              final formattedSurahId = surahId.padLeft(
                3,
                '0',
              ); // Make sure surah ID is like '001'
              final mediaItemId = '${moshaf.server}$formattedSurahId.mp3';

              mediaItems.add(
                MediaItem(
                  id: mediaItemId,
                  title: '${surahId.surahName} $formattedSurahId',
                  album: moshaf.name,
                  artist: reciter.name,
                  // Add other MediaItem properties as needed
                ),
              );
            }
          }
        }

        // Cache the results
        _cachedReciters = mediaItems;
        return mediaItems;
      } else {
        log('Error: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception: $e');
    } finally {
      _isLoadingReciters = false;
    }
    return null;
  }

  /// Get raw reciters data for the RecitersScreen
  @override
  Future<List<Reciter>?> getRecitersData() async {
    final baseUrl = "https://mp3quran.net/api/v3/reciters";

    try {
      final response = await Dio().get(baseUrl);

      if (response.statusCode == 200) {
        final map = response.data as Map<String, dynamic>;
        final recitersModel = RecitersModel.fromJson(map);
        return recitersModel.reciters;
      } else {
        log('Error getting reciters data: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception getting reciters data: $e');
    }
    return null;
  }

  /// Get surah list for a specific moshaf
  @override
  Future<List<MediaItem>?> getSurahListForMoshaf(
    Mosahf moshaf, {
    String? reciterName,
  }) async {
    try {
      final surahList = moshaf.surahList.split(',');
      final mediaItems = <MediaItem>[];

      for (var surahId in surahList) {
        final surahNumber = int.parse(surahId);
        final formattedSurahId = surahId.padLeft(3, '0');
        final mediaItemId = '${moshaf.server}$formattedSurahId.mp3';
        final surahName = _getSurahName(surahNumber);

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

  /// Get Arabic surah name by surah number
  String _getSurahName(int surahNumber) {
    const surahNames = {
      1: 'سورة الفاتحة',
      2: 'سورة البقرة',
      3: 'سورة آل عمران',
      4: 'سورة النساء',
      5: 'سورة المائدة',
      6: 'سورة الأنعام',
      7: 'سورة الأعراف',
      8: 'سورة الأنفال',
      9: 'سورة التوبة',
      10: 'سورة يونس',
      11: 'سورة هود',
      12: 'سورة يوسف',
      13: 'سورة الرعد',
      14: 'سورة إبراهيم',
      15: 'سورة الحجر',
      16: 'سورة النحل',
      17: 'سورة الإسراء',
      18: 'سورة الكهف',
      19: 'سورة مريم',
      20: 'سورة طه',
      21: 'سورة الأنبياء',
      22: 'سورة الحج',
      23: 'سورة المؤمنون',
      24: 'سورة النور',
      25: 'سورة الفرقان',
      26: 'سورة الشعراء',
      27: 'سورة النمل',
      28: 'سورة القصص',
      29: 'سورة العنكبوت',
      30: 'سورة الروم',
      31: 'سورة لقمان',
      32: 'سورة السجدة',
      33: 'سورة الأحزاب',
      34: 'سورة سبأ',
      35: 'سورة فاطر',
      36: 'سورة يس',
      37: 'سورة الصافات',
      38: 'سورة ص',
      39: 'سورة الزمر',
      40: 'سورة غافر',
      41: 'سورة فصلت',
      42: 'سورة الشورى',
      43: 'سورة الزخرف',
      44: 'سورة الدخان',
      45: 'سورة الجاثية',
      46: 'سورة الأحقاف',
      47: 'سورة محمد',
      48: 'سورة الفتح',
      49: 'سورة الحجرات',
      50: 'سورة ق',
      51: 'سورة الذاريات',
      52: 'سورة الطور',
      53: 'سورة النجم',
      54: 'سورة القمر',
      55: 'سورة الرحمن',
      56: 'سورة الواقعة',
      57: 'سورة الحديد',
      58: 'سورة المجادلة',
      59: 'سورة الحشر',
      60: 'سورة الممتحنة',
      61: 'سورة الصف',
      62: 'سورة الجمعة',
      63: 'سورة المنافقون',
      64: 'سورة التغابن',
      65: 'سورة الطلاق',
      66: 'سورة التحريم',
      67: 'سورة الملك',
      68: 'سورة القلم',
      69: 'سورة الحاقة',
      70: 'سورة المعارج',
      71: 'سورة نوح',
      72: 'سورة الجن',
      73: 'سورة المزمل',
      74: 'سورة المدثر',
      75: 'سورة القيامة',
      76: 'سورة الإنسان',
      77: 'سورة المرسلات',
      78: 'سورة النبأ',
      79: 'سورة النازعات',
      80: 'سورة عبس',
      81: 'سورة التكوير',
      82: 'سورة الانفطار',
      83: 'سورة المطففين',
      84: 'سورة الانشقاق',
      85: 'سورة البروج',
      86: 'سورة الطارق',
      87: 'سورة الأعلى',
      88: 'سورة الغاشية',
      89: 'سورة الفجر',
      90: 'سورة البلد',
      91: 'سورة الشمس',
      92: 'سورة الليل',
      93: 'سورة الضحى',
      94: 'سورة الشرح',
      95: 'سورة التين',
      96: 'سورة العلق',
      97: 'سورة القدر',
      98: 'سورة البينة',
      99: 'سورة الزلزلة',
      100: 'سورة العاديات',
      101: 'سورة القارعة',
      102: 'سورة التكاثر',
      103: 'سورة العصر',
      104: 'سورة الهمزة',
      105: 'سورة الفيل',
      106: 'سورة قريش',
      107: 'سورة الماعون',
      108: 'سورة الكوثر',
      109: 'سورة الكافرون',
      110: 'سورة النصر',
      111: 'سورة المسد',
      112: 'سورة الإخلاص',
      113: 'سورة الفلق',
      114: 'سورة الناس',
    };

    return surahNames[surahNumber] ?? 'سورة غير معروفة';
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
      if (_artistPlaylists.containsKey(artistId)) {
        final artistPlaylist = _artistPlaylists[artistId]!;
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
      final reciters = await getReciters();

      if (reciters != null) {
        // Filter the reciters list to find the media items belonging to the artist with the provided artistId
        final artistPlaylist = reciters
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
}

extension SurahNameX on String {
  String get surahName {
    final arabic = "سورة $this";

    return '$arabic $this';
  }
}
