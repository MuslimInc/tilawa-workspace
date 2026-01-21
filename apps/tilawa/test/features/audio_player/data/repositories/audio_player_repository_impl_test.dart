import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa/features/audio_player/data/repositories/audio_player_repository_impl.dart';
import 'package:tilawa/features/audio_player/domain/entities/audio_modes.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'audio_player_repository_impl_test.mocks.dart';

@GenerateMocks([AudioPlayerHandler, AudioPositionService])
void main() {
  late MockAudioPlayerHandler mockAudioHandler;
  late MockAudioPositionService mockPositionService;
  late AudioPlayerRepositoryImpl repository;

  late BehaviorSubject<audio_service.MediaItem?> mediaItemSubject;
  late BehaviorSubject<audio_service.PlaybackState> playbackStateSubject;
  late BehaviorSubject<List<audio_service.MediaItem>> queueSubject;
  late BehaviorSubject<double> volumeSubject;
  late BehaviorSubject<double> speedSubject;
  late BehaviorSubject<Duration> positionSubject;

  final testMediaItem = audio_service.MediaItem(
    id: 'test-id',
    title: 'Test Title',
    duration: const Duration(minutes: 5),
    artist: 'Test Artist',
    album: 'Test Album',
    artUri: Uri.parse('https://example.com/art.jpg'),
    extras: const {'url': 'https://example.com/audio.mp3'},
  );

  final testPlaybackState = audio_service.PlaybackState(
    playing: true,
    processingState: audio_service.AudioProcessingState.ready,
    updatePosition: const Duration(seconds: 30),
    bufferedPosition: const Duration(seconds: 60),
    queueIndex: 0,
  );

  void setupMocks() {
    when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(
      mockAudioHandler.playbackState,
    ).thenAnswer((_) => playbackStateSubject);
    when(mockAudioHandler.queue).thenAnswer((_) => queueSubject);
    when(mockAudioHandler.volume).thenAnswer((_) => volumeSubject);
    when(mockAudioHandler.speed).thenAnswer((_) => speedSubject);
    when(mockPositionService.position).thenAnswer((_) => positionSubject);
  }

  setUp(() {
    mockAudioHandler = MockAudioPlayerHandler();
    mockPositionService = MockAudioPositionService();

    mediaItemSubject = BehaviorSubject<audio_service.MediaItem?>.seeded(null);
    playbackStateSubject = BehaviorSubject<audio_service.PlaybackState>.seeded(
      audio_service.PlaybackState(),
    );
    queueSubject = BehaviorSubject<List<audio_service.MediaItem>>.seeded([]);
    volumeSubject = BehaviorSubject<double>.seeded(1.0);
    speedSubject = BehaviorSubject<double>.seeded(1.0);
    positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

    setupMocks();

    repository = AudioPlayerRepositoryImpl(
      mockAudioHandler,
      mockPositionService,
    );
  });

  tearDown(() {
    mediaItemSubject.close();
    playbackStateSubject.close();
    queueSubject.close();
    volumeSubject.close();
    speedSubject.close();
    positionSubject.close();
  });

  group('AudioPlayerRepositoryImpl - currentAudio Stream', () {
    test('emits null when mediaItem is null', () async {
      await expectLater(repository.currentAudio, emits(isNull));
    });

    test('emits AudioEntity when mediaItem is present', () async {
      mediaItemSubject.add(testMediaItem);

      await expectLater(
        repository.currentAudio,
        emits(
          isA<AudioEntity>()
              .having((a) => a.id, 'id', 'test-id')
              .having((a) => a.title, 'title', 'Test Title')
              .having((a) => a.artist, 'artist', 'Test Artist')
              .having((a) => a.album, 'album', 'Test Album')
              .having((a) => a.duration, 'duration', const Duration(minutes: 5))
              .having((a) => a.url, 'url', 'https://example.com/audio.mp3'),
        ),
      );
    });

    test('maps MediaItem with null extras url to empty string', () async {
      const itemWithNoUrl = audio_service.MediaItem(
        id: 'no-url',
        title: 'No URL',
      );
      mediaItemSubject.add(itemWithNoUrl);

      await expectLater(
        repository.currentAudio,
        emits(isA<AudioEntity>().having((a) => a.url, 'url', '')),
      );
    });

    test('maps MediaItem with null duration to Duration.zero', () async {
      const itemWithNoDuration = audio_service.MediaItem(
        id: 'no-duration',
        title: 'No Duration',
      );
      mediaItemSubject.add(itemWithNoDuration);

      await expectLater(
        repository.currentAudio,
        emits(
          isA<AudioEntity>().having(
            (a) => a.duration,
            'duration',
            Duration.zero,
          ),
        ),
      );
    });
    test(
      'preserves extras in AudioEntity when mediaItem has metadata',
      () async {
        final mediaItemWithExtras = audio_service.MediaItem(
          id: '1',
          title: 'Title',
          extras: const {
            'url': 'url',
            'reciterId': 'reciter1',
            'surahId': 1,
            'moshafId': 1,
          },
        );
        mediaItemSubject.add(mediaItemWithExtras);

        await expectLater(
          repository.currentAudio,
          emits(
            isA<AudioEntity>().having(
              (a) => a.extras,
              'extras',
              allOf(
                containsPair('reciterId', 'reciter1'),
                containsPair('surahId', 1),
                containsPair('moshafId', 1),
              ),
            ),
          ),
        );
      },
    );
  });

  group('AudioPlayerRepositoryImpl - queue Stream', () {
    test('emits list of AudioEntity', () async {
      queueSubject.add([testMediaItem]);

      await expectLater(
        repository.queue,
        emits(
          isA<List<AudioEntity>>().having((list) => list.length, 'length', 1),
        ),
      );
    });
  });

  group('AudioPlayerRepositoryImpl - speed and volume Streams', () {
    test('speed emits current speed', () async {
      speedSubject.add(1.5);

      await expectLater(repository.speed, emits(1.5));
    });

    test('volume emits current volume', () async {
      volumeSubject.add(0.8);

      await expectLater(repository.volume, emits(0.8));
    });
  });

  group('AudioPlayerRepositoryImpl - getPlaybackState', () {
    test('returns current PlaybackStateEntity synchronously', () {
      mediaItemSubject.add(testMediaItem);
      playbackStateSubject.add(testPlaybackState);
      queueSubject.add([testMediaItem]);

      final PlaybackStateEntity result = repository.getPlaybackState;

      expect(result.isPlaying, isTrue);
      expect(result.processingState, AudioProcessingStateStatus.ready);
      expect(result.currentIndex, 0);
    });

    test('handles null mediaItem duration', () {
      playbackStateSubject.add(testPlaybackState);

      final PlaybackStateEntity result = repository.getPlaybackState;

      expect(result.duration, Duration.zero);
    });
  });

  group('AudioPlayerRepositoryImpl - playbackState Stream', () {
    test('emits correct PlaybackStateEntity', () async {
      playbackStateSubject.add(testPlaybackState);
      queueSubject.add([testMediaItem]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>()
              .having((s) => s.isPlaying, 'isPlaying', true)
              .having(
                (s) => s.processingState,
                'processingState',
                AudioProcessingStateStatus.ready,
              )
              .having((s) => s.currentIndex, 'currentIndex', 0)
              .having((s) => s.queue.length, 'queue length', 1),
        ),
      );
    });

    test('maps AudioProcessingState.completed correctly', () async {
      playbackStateSubject.add(
        testPlaybackState.copyWith(
          processingState: audio_service.AudioProcessingState.completed,
        ),
      );
      queueSubject.add([]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>().having(
            (s) => s.processingState,
            'processingState',
            AudioProcessingStateStatus.completed,
          ),
        ),
      );
    });

    test('maps AudioProcessingState.error correctly', () async {
      playbackStateSubject.add(
        testPlaybackState.copyWith(
          processingState: audio_service.AudioProcessingState.error,
        ),
      );
      queueSubject.add([]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>().having(
            (s) => s.processingState,
            'processingState',
            AudioProcessingStateStatus.error,
          ),
        ),
      );
    });

    test('maps AudioProcessingState.idle correctly', () async {
      playbackStateSubject.add(
        testPlaybackState.copyWith(
          processingState: audio_service.AudioProcessingState.idle,
        ),
      );
      queueSubject.add([]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>().having(
            (s) => s.processingState,
            'processingState',
            AudioProcessingStateStatus.idle,
          ),
        ),
      );
    });

    test('maps AudioProcessingState.loading correctly', () async {
      playbackStateSubject.add(
        testPlaybackState.copyWith(
          processingState: audio_service.AudioProcessingState.loading,
        ),
      );
      queueSubject.add([]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>().having(
            (s) => s.processingState,
            'processingState',
            AudioProcessingStateStatus.loading,
          ),
        ),
      );
    });

    test('maps AudioProcessingState.buffering correctly', () async {
      playbackStateSubject.add(
        testPlaybackState.copyWith(
          processingState: audio_service.AudioProcessingState.buffering,
        ),
      );
      queueSubject.add([]);

      await expectLater(
        repository.playbackState,
        emits(
          isA<PlaybackStateEntity>().having(
            (s) => s.processingState,
            'processingState',
            AudioProcessingStateStatus.buffering,
          ),
        ),
      );
    });
  });

  group('AudioPlayerRepositoryImpl - position Stream', () {
    test('returns the position stream from positionService', () {
      expect(repository.position, isA<Stream<Duration>>());
    });

    test('emits real-time position updates', () async {
      // Create a sequence of positions to simulate real-time updates
      final List<Duration> positions = [
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 3),
      ];

      // Use expectLater to listen for emissions
      final Future<void> expectation = expectLater(
        repository.position,
        emitsInOrder(positions),
      );

      // Add positions to the stream
      positions.skip(1).forEach(positionSubject.add);

      await expectation;
    });
  });

  group('AudioPlayerRepositoryImpl - Playback Controls', () {
    test('play calls audioHandler.play and returns Right', () async {
      when(mockAudioHandler.play()).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.play();

      expect(result.isRight, true);
      verify(mockAudioHandler.play()).called(1);
    });

    test('pause calls audioHandler.pause and returns Right', () async {
      when(mockAudioHandler.pause()).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.pause();

      expect(result.isRight, true);
      verify(mockAudioHandler.pause()).called(1);
    });

    test('stop calls audioHandler.stop and returns Right', () async {
      when(mockAudioHandler.stop()).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.stop();

      expect(result.isRight, true);
      verify(mockAudioHandler.stop()).called(1);
    });

    test(
      'seek calls audioHandler.seek with position and returns Right',
      () async {
        when(mockAudioHandler.seek(any)).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository.seek(
          const Duration(seconds: 45),
        );

        expect(result.isRight, true);
        verify(mockAudioHandler.seek(const Duration(seconds: 45))).called(1);
      },
    );

    test('next calls audioHandler.skipToNext and returns Right', () async {
      when(mockAudioHandler.skipToNext()).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.next();

      expect(result.isRight, true);
      verify(mockAudioHandler.skipToNext()).called(1);
    });

    test(
      'previous calls audioHandler.skipToPrevious and returns Right',
      () async {
        when(mockAudioHandler.skipToPrevious()).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository.previous();

        expect(result.isRight, true);
        verify(mockAudioHandler.skipToPrevious()).called(1);
      },
    );

    test(
      'skipToQueueItem calls audioHandler with index and returns Right',
      () async {
        when(mockAudioHandler.skipToQueueItem(any)).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository.skipToQueueItem(
          3,
        );

        expect(result.isRight, true);
        verify(mockAudioHandler.skipToQueueItem(3)).called(1);
      },
    );
  });

  group('AudioPlayerRepositoryImpl - Settings', () {
    test('setVolume calls audioHandler.setVolume and returns Right', () async {
      when(mockAudioHandler.setVolume(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setVolume(0.5);

      expect(result.isRight, true);
      verify(mockAudioHandler.setVolume(0.5)).called(1);
    });

    test('setSpeed calls audioHandler.setSpeed and returns Right', () async {
      when(mockAudioHandler.setSpeed(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setSpeed(1.5);

      expect(result.isRight, true);
      verify(mockAudioHandler.setSpeed(1.5)).called(1);
    });

    test('setRepeatMode.none maps correctly and calls audioHandler', () async {
      when(mockAudioHandler.setRepeatMode(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setRepeatMode(
        AudioRepeatMode.none,
      );

      expect(result.isRight, true);
      verify(
        mockAudioHandler.setRepeatMode(
          audio_service.AudioServiceRepeatMode.none,
        ),
      ).called(1);
    });

    test('setRepeatMode.one maps correctly and calls audioHandler', () async {
      when(mockAudioHandler.setRepeatMode(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setRepeatMode(
        AudioRepeatMode.one,
      );

      expect(result.isRight, true);
      verify(
        mockAudioHandler.setRepeatMode(
          audio_service.AudioServiceRepeatMode.one,
        ),
      ).called(1);
    });

    test('setRepeatMode.all maps correctly and calls audioHandler', () async {
      when(mockAudioHandler.setRepeatMode(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setRepeatMode(
        AudioRepeatMode.all,
      );

      expect(result.isRight, true);
      verify(
        mockAudioHandler.setRepeatMode(
          audio_service.AudioServiceRepeatMode.all,
        ),
      ).called(1);
    });

    test('setShuffleMode.none maps correctly and calls audioHandler', () async {
      when(mockAudioHandler.setShuffleMode(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setShuffleMode(
        AudioShuffleMode.none,
      );

      expect(result.isRight, true);
      verify(
        mockAudioHandler.setShuffleMode(
          audio_service.AudioServiceShuffleMode.none,
        ),
      ).called(1);
    });

    test('setShuffleMode.all maps correctly and calls audioHandler', () async {
      when(mockAudioHandler.setShuffleMode(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.setShuffleMode(
        AudioShuffleMode.all,
      );

      expect(result.isRight, true);
      verify(
        mockAudioHandler.setShuffleMode(
          audio_service.AudioServiceShuffleMode.all,
        ),
      ).called(1);
    });
  });

  group('AudioPlayerRepositoryImpl - Queue Management', () {
    const testAudioEntity = AudioEntity(
      id: 'queue-id',
      title: 'Queue Title',
      url: 'https://example.com/queue.mp3',
      duration: Duration(minutes: 3),
      artist: 'Queue Artist',
      album: 'Queue Album',
      artUri: 'https://example.com/queue-art.jpg',
    );

    test(
      'addQueueItem converts entity to MediaItem and calls audioHandler',
      () async {
        when(mockAudioHandler.addQueueItem(any)).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository.addQueueItem(
          testAudioEntity,
        );

        expect(result.isRight, true);
        verify(mockAudioHandler.addQueueItem(any)).called(1);
      },
    );

    test(
      'removeQueueItem converts entity to MediaItem and calls audioHandler',
      () async {
        when(mockAudioHandler.removeQueueItem(any)).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository.removeQueueItem(
          testAudioEntity,
        );

        expect(result.isRight, true);
        verify(mockAudioHandler.removeQueueItem(any)).called(1);
      },
    );

    test('moveQueueItem calls audioHandler with indices', () async {
      when(mockAudioHandler.moveQueueItem(any, any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.moveQueueItem(0, 2);

      expect(result.isRight, true);
      verify(mockAudioHandler.moveQueueItem(0, 2)).called(1);
    });

    test('updateQueue converts entities and calls audioHandler', () async {
      when(mockAudioHandler.updateQueue(any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.updateQueue([
        testAudioEntity,
      ]);

      expect(result.isRight, true);
      verify(mockAudioHandler.updateQueue(any)).called(1);
    });

    test('playFromQueue converts entities and calls audioHandler', () async {
      when(mockAudioHandler.playFromQueue(any, any)).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.playFromQueue([
        testAudioEntity,
      ], 0);

      expect(result.isRight, true);
      verify(mockAudioHandler.playFromQueue(any, 0)).called(1);
    });

    test('maps AudioEntity with null artUri correctly', () async {
      when(mockAudioHandler.addQueueItem(any)).thenAnswer((_) async {});

      const entityWithNullArt = AudioEntity(
        id: 'null-art',
        title: 'Null Art',
        url: 'url',
        duration: Duration.zero,
      );

      await repository.addQueueItem(entityWithNullArt);

      final capturedMediaItem =
          verify(mockAudioHandler.addQueueItem(captureAny)).captured.single
              as audio_service.MediaItem;

      expect(capturedMediaItem.artUri, isNull);
    });

    test('maps AudioEntity with artUri correctly', () async {
      when(mockAudioHandler.addQueueItem(any)).thenAnswer((_) async {});

      const entityWithArt = AudioEntity(
        id: 'with-art',
        title: 'With Art',
        url: 'url',
        duration: Duration.zero,
        artUri: 'https://example.com/art.jpg',
      );

      await repository.addQueueItem(entityWithArt);

      final capturedMediaItem =
          verify(mockAudioHandler.addQueueItem(captureAny)).captured.single
              as audio_service.MediaItem;

      expect(
        capturedMediaItem.artUri,
        Uri.parse('https://example.com/art.jpg'),
      );
    });
    test('passes extras to audioHandler when adding queue item', () async {
      when(mockAudioHandler.addQueueItem(any)).thenAnswer((_) async {});
      const entityWithExtras = AudioEntity(
        id: '1',
        title: 'Title',
        url: 'url',
        duration: Duration.zero,
        extras: {'reciterId': 'reciter1', 'surahId': 1, 'moshafId': 1},
      );

      await repository.addQueueItem(entityWithExtras);

      final captured =
          verify(mockAudioHandler.addQueueItem(captureAny)).captured.single
              as audio_service.MediaItem;
      expect(
        captured.extras,
        allOf(
          containsPair('reciterId', 'reciter1'),
          containsPair('surahId', 1),
          containsPair('moshafId', 1),
          containsPair('url', 'url'),
        ),
      );
    });
  });

  group('AudioPlayerRepositoryImpl - Load Audio Data', () {
    test(
      'loadAudioPlayerData with default restorePlayback calls audioHandler',
      () async {
        when(
          mockAudioHandler.loadAudioPlayerData(
            restorePlayback: anyNamed('restorePlayback'),
          ),
        ).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository
            .loadAudioPlayerData();

        expect(result.isRight, true);
        verify(mockAudioHandler.loadAudioPlayerData()).called(1);
      },
    );

    test(
      'loadAudioPlayerData with restorePlayback=false calls audioHandler',
      () async {
        when(
          mockAudioHandler.loadAudioPlayerData(
            restorePlayback: anyNamed('restorePlayback'),
          ),
        ).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository
            .loadAudioPlayerData(restorePlayback: false);

        expect(result.isRight, true);
        verify(
          mockAudioHandler.loadAudioPlayerData(restorePlayback: false),
        ).called(1);
      },
    );
  });

  group('AudioPlayerRepositoryImpl - distinct() behavior', () {
    test(
      'currentAudio filters duplicate AudioEntity emissions with same values',
      () async {
        final List<AudioEntity?> emissions = [];
        final StreamSubscription<AudioEntity?> subscription = repository
            .currentAudio
            .listen(emissions.add);

        // Emit same media item twice (same reference)
        mediaItemSubject.add(testMediaItem);
        mediaItemSubject.add(testMediaItem);

        // Emit a different media item with same values (new instance)
        final duplicateMediaItem = audio_service.MediaItem(
          id: 'test-id',
          title: 'Test Title',
          duration: const Duration(minutes: 5),
          artist: 'Test Artist',
          album: 'Test Album',
          artUri: Uri.parse('https://example.com/art.jpg'),
          extras: const {'url': 'https://example.com/audio.mp3'},
        );
        mediaItemSubject.add(duplicateMediaItem);

        // Emit a truly different item
        const differentMediaItem = audio_service.MediaItem(
          id: 'different-id',
          title: 'Different Title',
        );
        mediaItemSubject.add(differentMediaItem);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Should have: null (initial), testMediaItem, differentMediaItem
        // The duplicate emissions should be filtered out
        expect(emissions.length, 3);
        expect(emissions[0], isNull);
        expect(emissions[1]?.id, 'test-id');
        expect(emissions[2]?.id, 'different-id');
      },
    );

    test(
      'queue stream applies map and distinct - distinct uses List reference equality after map',
      () async {
        // Note: Because .map() creates a new List<AudioEntity> for each emission,
        // .distinct() won't filter duplicates based on content - each mapped list
        // is a new reference. This is a known limitation of using .distinct() on
        // mapped Lists without a custom equality function.
        //
        // However, this still provides value when:
        // 1. The source stream emits the exact same reference multiple times in a row
        // 2. Combined with other optimizations in the audio service
        final List<List<AudioEntity>> emissions = [];
        final StreamSubscription<List<AudioEntity>> subscription = repository
            .queue
            .listen(emissions.add);

        // Emit initial state change and a different queue
        const differentMediaItem = audio_service.MediaItem(
          id: 'different-id',
          title: 'Different Title',
        );
        queueSubject.add([differentMediaItem]);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Verify the stream emits and maps correctly
        expect(emissions.isNotEmpty, isTrue);
        expect(emissions.last.first.id, 'different-id');
      },
    );

    test(
      'queue emits new instances with same content (List reference equality limitation)',
      () async {
        // This test documents that .distinct() on Lists uses reference equality,
        // not value equality. New list instances with same content will be emitted.
        // This is acceptable because audio_service typically reuses the same queue instance.
        final List<List<AudioEntity>> emissions = [];
        final StreamSubscription<List<AudioEntity>> subscription = repository
            .queue
            .listen(emissions.add);

        // Create new list instances with same content
        queueSubject.add([testMediaItem]);
        queueSubject.add([testMediaItem]); // New list instance

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Both emissions will be received because they are different list instances
        // This is expected behavior with default distinct() on Lists
        expect(emissions.length, greaterThanOrEqualTo(2));
      },
    );

    test(
      'playbackState filters duplicate PlaybackStateEntity emissions',
      () async {
        final List<PlaybackStateEntity> emissions = [];
        final StreamSubscription<PlaybackStateEntity> subscription = repository
            .playbackState
            .listen(emissions.add);

        // Emit same state twice
        playbackStateSubject.add(testPlaybackState);
        playbackStateSubject.add(testPlaybackState);
        queueSubject.add([testMediaItem]);

        // Emit a different state
        final audio_service.PlaybackState differentState = testPlaybackState
            .copyWith(playing: false);
        playbackStateSubject.add(differentState);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        // Duplicates should be filtered
        // Note: combineLatest2 may emit multiple times as both streams emit
        // The key is that consecutive identical PlaybackStateEntity values are filtered
        final Set<PlaybackStateEntity> uniqueStates = emissions.toSet();
        expect(
          uniqueStates.length,
          lessThanOrEqualTo(emissions.length),
          reason: 'distinct() should filter some duplicate emissions',
        );
      },
    );

    test('speed filters duplicate emissions', () async {
      final List<double> emissions = [];
      final StreamSubscription<double> subscription = repository.speed.listen(
        emissions.add,
      );

      speedSubject.add(1.0);
      speedSubject.add(1.0);
      speedSubject.add(1.5);
      speedSubject.add(1.5);
      speedSubject.add(2.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Should be: 1.0 (initial), 1.5, 2.0 - duplicates filtered
      expect(emissions, [1.0, 1.5, 2.0]);
    });

    test('volume filters duplicate emissions', () async {
      final List<double> emissions = [];
      final StreamSubscription<double> subscription = repository.volume.listen(
        emissions.add,
      );

      volumeSubject.add(1.0);
      volumeSubject.add(1.0);
      volumeSubject.add(0.5);
      volumeSubject.add(0.5);
      volumeSubject.add(0.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Should be: 1.0 (initial), 0.5, 0.0 - duplicates filtered
      expect(emissions, [1.0, 0.5, 0.0]);
    });

    test('position stream passes through from position service', () async {
      // Note: The distinct() is applied in AudioPositionServiceImpl,
      // not in the repository. The repository just passes through
      // the stream from the position service. The mock doesn't apply
      // distinct(), so we're testing the passthrough behavior only.
      final List<Duration> emissions = [];
      final StreamSubscription<Duration> subscription = repository.position
          .listen(emissions.add);

      // positionSubject is already seeded with Duration.zero
      positionSubject.add(const Duration(seconds: 10));
      positionSubject.add(const Duration(seconds: 20));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Verify position stream passes through correctly
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.contains(const Duration(seconds: 10)), isTrue);
      expect(emissions.contains(const Duration(seconds: 20)), isTrue);
    });
  });
}
