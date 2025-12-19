import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/position_data.dart';
import 'package:muzakri/shared/models/queue_state.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'audio_player_bloc_test.mocks.dart';

@GenerateMocks([AudioPlayerHandler])
void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  late MockAudioPlayerHandler mockAudioHandler;
  late BehaviorSubject<MediaItem?> mediaItemSubject;
  late BehaviorSubject<PlaybackState> playbackStateSubject;
  late BehaviorSubject<QueueState> queueStateSubject;
  late BehaviorSubject<List<MediaItem>> queueSubject;
  late BehaviorSubject<double> volumeSubject;
  late BehaviorSubject<double> speedSubject;

  setUp(() {
    mockAudioHandler = MockAudioPlayerHandler();

    mediaItemSubject = BehaviorSubject<MediaItem?>();
    playbackStateSubject = BehaviorSubject<PlaybackState>();
    queueStateSubject = BehaviorSubject<QueueState>();
    queueSubject = BehaviorSubject<List<MediaItem>>.seeded([]);
    volumeSubject = BehaviorSubject<double>.seeded(1.0);
    speedSubject = BehaviorSubject<double>.seeded(1.0);

    // Setup mock streams
    when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(
      mockAudioHandler.playbackState,
    ).thenAnswer((_) => playbackStateSubject);
    when(mockAudioHandler.queueState).thenAnswer((_) => queueStateSubject);
    when(mockAudioHandler.queue).thenAnswer((_) => queueSubject);
    when(mockAudioHandler.volume).thenAnswer((_) => volumeSubject);
    when(mockAudioHandler.speed).thenAnswer((_) => speedSubject);
  });

  tearDown(() {
    mediaItemSubject.close();
    playbackStateSubject.close();
    queueStateSubject.close();
    queueSubject.close();
    volumeSubject.close();
    speedSubject.close();
  });

  group('AudioPlayerBloc - LoadAudioPlayerData', () {
    test('initial state is correct', () {
      final bloc = AudioPlayerBloc(mockAudioHandler);
      expect(
        bloc.state,
        const AudioPlayerState(status: AudioPlayerStatus.initial),
      );
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when mediaItem stream has value, should restore state',
      setUp: () {
        // Create a test media item
        const testMediaItem = MediaItem(
          id: 'test-id',
          title: 'Test Title',
          artist: 'Test Artist',
          duration: Duration(minutes: 3),
        );

        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          playing: true,
          updateTime: DateTime.now(),
          queueIndex: 0,
        );

        const testQueueState = QueueState(
          queue: [testMediaItem],
          queueIndex: 0,
          shuffleIndices: null,
          repeatMode: AudioServiceRepeatMode.none,
        );

        // Add values to subjects immediately
        mediaItemSubject.add(testMediaItem);
        playbackStateSubject.add(testPlaybackState);
        queueStateSubject.add(testQueueState);
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      wait: const Duration(seconds: 2), // Wait for async operations
      skip: 1, // Skip the first state (mediaItem only, no playbackState yet)
      expect: () => [
        // State with mediaItem and playbackState
        isA<AudioPlayerState>()
            .having((s) => s.status, 'status', AudioPlayerStatus.success)
            .having((s) => s.mediaItem, 'mediaItem', isNotNull)
            .having((s) => s.mediaItem?.id, 'mediaItem.id', 'test-id')
            .having((s) => s.playbackState, 'playbackState', isNotNull)
            .having((s) => s.playbackState?.playing, 'playing', true),
        // State with queueState added (from stream listener)
        isA<AudioPlayerState>().having(
          (s) => s.queueState,
          'queueState',
          isNotNull,
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when mediaItem stream emits after delay, should restore state',
      setUp: () {
        // Create a test media item
        const testMediaItem = MediaItem(
          id: 'test-id-2',
          title: 'Test Title 2',
          artist: 'Test Artist 2',
          duration: Duration(minutes: 5),
        );

        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          updateTime: DateTime.now(),
          queueIndex: 0,
        );

        // Emit values after a delay to simulate stream not having value immediately
        Future.delayed(const Duration(milliseconds: 100), () {
          mediaItemSubject.add(testMediaItem);
          playbackStateSubject.add(testPlaybackState);
        });
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      wait: const Duration(seconds: 2),
      skip: 1, // Skip the initial state (no mediaItem yet)
      expect: () => [
        // State with mediaItem from loadAudioPlayerData
        isA<AudioPlayerState>()
            .having((s) => s.status, 'status', AudioPlayerStatus.success)
            .having((s) => s.mediaItem, 'mediaItem', isNotNull)
            .having((s) => s.mediaItem?.id, 'mediaItem.id', 'test-id-2'),
        // State with playbackState added (from stream listener)
        isA<AudioPlayerState>().having(
          (s) => s.playbackState,
          'playbackState',
          isNotNull,
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when mediaItem stream never emits, should not restore mediaItem',
      setUp: () {
        // Don't add any values to the stream
        // This simulates the case where audio is not playing
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      wait: const Duration(seconds: 2),
      expect: () => [
        // State from loadAudioPlayerData (no mediaItem found)
        // Initial state is emitted during bloc construction, before bloc_test captures states
        isA<AudioPlayerState>()
            .having((s) => s.status, 'status', AudioPlayerStatus.success)
            .having((s) => s.mediaItem, 'mediaItem', isNull)
            .having((s) => s.volume, 'volume', 1.0)
            .having((s) => s.speed, 'speed', 1.0),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when valueOrNull returns value, should use it immediately',
      setUp: () {
        // Create a test media item
        const testMediaItem = MediaItem(
          id: 'test-id-3',
          title: 'Test Title 3',
          artist: 'Test Artist 3',
        );

        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          playing: true,
          updateTime: DateTime.now(),
          queueIndex: 0,
        );

        // Add values to subjects so valueOrNull will return them
        mediaItemSubject.add(testMediaItem);
        playbackStateSubject.add(testPlaybackState);
      },
      build: () {
        // Create a ValueStream mock that has a value
        final ValueStream<MediaItem?> mediaItemValueStream = mediaItemSubject
            .shareValueSeeded(null);
        when(
          mockAudioHandler.mediaItem,
        ).thenAnswer((_) => mediaItemValueStream);
        return AudioPlayerBloc(mockAudioHandler);
      },
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      wait: const Duration(seconds: 2),
      skip: 1, // Skip the initial playbackState update from stream setup
      expect: () => [
        // State with mediaItem from loadAudioPlayerData
        isA<AudioPlayerState>()
            .having((s) => s.status, 'status', AudioPlayerStatus.success)
            .having((s) => s.mediaItem, 'mediaItem', isNotNull),
      ],
    );
  });

  group('AudioPlayerBloc - Stream Setup', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'stream setup - should emit state when mediaItem stream emits',
      setUp: () {
        const testMediaItem = MediaItem(
          id: 'stream-test',
          title: 'Stream Test',
          artist: 'Stream Artist',
        );
        // Don't add immediately, let stream emit later
        Future.delayed(const Duration(milliseconds: 50), () {
          mediaItemSubject.add(testMediaItem);
        });
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      wait: const Duration(milliseconds: 200),
      skip: 1, // Skip the initial state emission
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.mediaItem, 'mediaItem', isNotNull)
            .having((s) => s.mediaItem?.id, 'mediaItem.id', 'stream-test'),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'stream setup - should emit state when playbackState stream emits',
      setUp: () {
        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          playing: true,
          updateTime: DateTime.now(),
          queueIndex: 0,
        );
        Future.delayed(const Duration(milliseconds: 50), () {
          playbackStateSubject.add(testPlaybackState);
        });
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      wait: const Duration(milliseconds: 200),
      skip: 1, // Skip the initial state emission
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.playbackState, 'playbackState', isNotNull)
            .having((s) => s.playbackState?.playing, 'playing', true),
      ],
    );
  });

  group('AudioPlayerBloc - Integration with BottomPlayerWidget', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should have mediaItem after loadAudioPlayerData when audio is playing',
      setUp: () {
        const testMediaItem = MediaItem(
          id: 'integration-test',
          title: 'Integration Test',
          artist: 'Integration Artist',
          duration: Duration(minutes: 2),
        );

        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          playing: true,
          updatePosition: const Duration(seconds: 30),
          updateTime: DateTime.now(),
          queueIndex: 0,
        );

        const testQueueState = QueueState(
          queue: [testMediaItem],
          queueIndex: 0,
          shuffleIndices: null,
          repeatMode: AudioServiceRepeatMode.none,
        );

        // Simulate audio already playing - add values immediately
        mediaItemSubject.add(testMediaItem);
        playbackStateSubject.add(testPlaybackState);
        queueStateSubject.add(testQueueState);
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      wait: const Duration(seconds: 2),
      verify: (bloc) {
        final AudioPlayerState state = bloc.state;
        expect(state.hasMediaItem, true, reason: 'hasMediaItem should be true');
        expect(
          state.mediaItem,
          isNotNull,
          reason: 'mediaItem should not be null',
        );
        expect(
          state.status,
          AudioPlayerStatus.success,
          reason: 'status should be success',
        );
      },
    );
  });

  group('AudioPlayerBloc - State Persistence', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'toJson should persist queue, queueIndex, and position',
      setUp: () {
        const testMediaItem1 = MediaItem(
          id: 'test-1',
          title: 'Test Track 1',
          artist: 'Test Artist',
          duration: Duration(minutes: 3),
        );
        const testMediaItem2 = MediaItem(
          id: 'test-2',
          title: 'Test Track 2',
          artist: 'Test Artist',
          duration: Duration(minutes: 4),
        );

        final testPlaybackState = PlaybackState(
          controls: [],
          processingState: AudioProcessingState.ready,
          playing: true,
          updateTime: DateTime.now(),
          queueIndex: 1,
        );

        const testQueueState = QueueState(
          queue: [testMediaItem1, testMediaItem2],
          queueIndex: 1,
          shuffleIndices: null,
          repeatMode: AudioServiceRepeatMode.none,
        );

        // Add values to subjects
        mediaItemSubject.add(testMediaItem2);
        playbackStateSubject.add(testPlaybackState);
        queueStateSubject.add(testQueueState);
      },
      build: () => AudioPlayerBloc(mockAudioHandler),
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        // Get the serialized state
        final Map<String, dynamic>? json = bloc.toJson(bloc.state);
        expect(json, isNotNull);
        expect(json!['queue'], isNotNull);
        expect(json['queueIndex'], 1);
        expect((json['queue'] as List).length, 2);
      },
    );

    test('fromJson should restore queue and position', () {
      final bloc = AudioPlayerBloc(mockAudioHandler);
      final Map<String, Object> json = {
        'volume': 0.8,
        'speed': 1.5,
        'queue': [
          {
            'id': 'restored-1',
            'title': 'Restored Track 1',
            'artist': 'Restored Artist',
            'album': 'Test Album',
            'duration': 180000, // 3 minutes in milliseconds
          },
          {
            'id': 'restored-2',
            'title': 'Restored Track 2',
            'artist': 'Restored Artist',
            'album': 'Test Album',
            'duration': 240000, // 4 minutes in milliseconds
          },
        ],
        'queueIndex': 1,
        'position': 45000, // 45 seconds in milliseconds
      };

      final AudioPlayerState? state = bloc.fromJson(json);

      expect(state, isNotNull);
      expect(state!.volume, 0.8);
      expect(state.speed, 1.5);
      expect(state.queueState, isNotNull);
      expect(state.queueState!.queue.length, 2);
      expect(state.queueState!.queueIndex, 1);
      expect(state.queueState!.queue[0].id, 'restored-1');
      expect(state.queueState!.queue[1].title, 'Restored Track 2');
      expect(state.positionData, isNotNull);
      expect(state.positionData!.position, const Duration(seconds: 45));
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData should restore queue from persisted state',
      setUp: () {
        // Mock playFromQueue to track calls
        when(mockAudioHandler.playFromQueue(any, any)).thenAnswer((_) async {});
        when(mockAudioHandler.seek(any)).thenAnswer((_) async {});
        when(mockAudioHandler.pause()).thenAnswer((_) async {});
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.initial,
        queueState: QueueState(
          queue: [
            MediaItem(
              id: 'persisted-1',
              title: 'Persisted Track',
              artist: 'Persisted Artist',
            ),
          ],
          queueIndex: 0,
          shuffleIndices: null,
          repeatMode: AudioServiceRepeatMode.none,
        ),
        positionData: PositionData(
          position: Duration(seconds: 30),
          bufferedPosition: Duration.zero,
          duration: Duration.zero,
        ),
      ),
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
      wait: const Duration(seconds: 1),
      verify: (_) {
        // Verify that playFromQueue was called with the persisted queue
        verify(
          mockAudioHandler.playFromQueue(
            any,
            0, // index from persisted state
          ),
        ).called(1);
        // Verify that seek was called with the persisted position
        verify(mockAudioHandler.seek(const Duration(seconds: 30))).called(1);
        // Verify that pause was called (user needs to press play)
        verify(mockAudioHandler.pause()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when restoration disabled, should clear persisted state',
      build: () => AudioPlayerBloc(mockAudioHandler),
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.initial,
        queueState: QueueState(
          queue: [
            MediaItem(id: '1', title: 'Persisted', album: 'A', artist: 'Art'),
          ],
          queueIndex: 0,
          shuffleIndices: null,
          repeatMode: AudioServiceRepeatMode.none,
        ),
        positionData: PositionData(
          position: Duration(seconds: 10),
          bufferedPosition: Duration.zero,
          duration: Duration.zero,
        ),
      ),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.loadAudioPlayerData(restorePlayback: false),
      ),
      wait: const Duration(seconds: 2),
      skip: 1, // Skip initial side-effect emission
      expect: () => [const AudioPlayerState(status: AudioPlayerStatus.success)],
      verify: (_) {
        verifyNever(mockAudioHandler.playFromQueue(any, any));
      },
    );
  });
  group('AudioPlayerBloc - State Update Events', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateMediaItem should update state with new media item',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateMediaItem(
          MediaItem(id: 'new-id', title: 'New Title'),
        ),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.mediaItem, 'mediaItem', isNotNull)
            .having((s) => s.mediaItem?.id, 'mediaItem.id', 'new-id'),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdatePlaybackState should update state with new playback state',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        AudioPlayerEvent.updatePlaybackState(PlaybackState(playing: true)),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.playbackState, 'playbackState', isNotNull)
            .having((s) => s.playbackState?.playing, 'playing', true),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdatePositionData should update state with new position data',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updatePositionData(
          PositionData(
            position: Duration(seconds: 10),
            bufferedPosition: Duration(seconds: 20),
            duration: Duration(seconds: 30),
          ),
        ),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.positionData, 'positionData', isNotNull)
            .having(
              (s) => s.positionData?.position,
              'position',
              const Duration(seconds: 10),
            ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateQueueState should update state with new queue state',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateQueueState(
          QueueState(
            queue: [],
            queueIndex: 1,
            shuffleIndices: [],
            repeatMode: AudioServiceRepeatMode.all,
          ),
        ),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.queueState, 'queueState', isNotNull)
            .having((s) => s.queueState?.queueIndex, 'queueIndex', 1),
      ],
    );
  });

  group('AudioPlayerBloc - State Update Events (Volume/Speed)', () {
    // Uses parent setUp with default seeds (1.0), which causes no initial emission
    // since AudioPlayerState defaults are 1.0.

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateVolume should update state with new volume',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) async {
        await Future.delayed(Duration.zero); // Ensure init completes
        bloc.add(const AudioPlayerEvent.updateVolume(0.5));
      },
      skip: 1, // Skip initialization emission from UpdatePlaybackState
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.volume, 'volume', 0.5),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateSpeed should update state with new speed',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) async {
        await Future.delayed(Duration.zero); // Ensure init completes
        bloc.add(const AudioPlayerEvent.updateSpeed(1.5));
      },
      skip: 1, // Skip initialization emission from UpdatePlaybackState
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.speed, 'speed', 1.5),
      ],
    );
  });

  group('AudioPlayerBloc - Audio Control Events (Command Delegation)', () {
    setUp(() {
      // Mock audio handler methods
      when(mockAudioHandler.play()).thenAnswer((_) async {});
      when(mockAudioHandler.pause()).thenAnswer((_) async {});
      when(mockAudioHandler.stop()).thenAnswer((_) async {});
      when(mockAudioHandler.skipToNext()).thenAnswer((_) async {});
      when(mockAudioHandler.skipToPrevious()).thenAnswer((_) async {});
      when(mockAudioHandler.seek(any)).thenAnswer((_) async {});
      when(mockAudioHandler.skipToQueueItem(any)).thenAnswer((_) async {});
      when(mockAudioHandler.playFromQueue(any, any)).thenAnswer((_) async {});
      when(mockAudioHandler.updateQueue(any)).thenAnswer((_) async {});
      when(mockAudioHandler.addQueueItem(any)).thenAnswer((_) async {});
      when(mockAudioHandler.removeQueueItem(any)).thenAnswer((_) async {});
      when(mockAudioHandler.moveQueueItem(any, any)).thenAnswer((_) async {});
      when(mockAudioHandler.setRepeatMode(any)).thenAnswer((_) async {});
      when(mockAudioHandler.setShuffleMode(any)).thenAnswer((_) async {});
      when(mockAudioHandler.setVolume(any)).thenAnswer((_) async {});
      when(mockAudioHandler.setSpeed(any)).thenAnswer((_) async {});
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PlayAudio should call audioHandler.play',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.playAudio()),
      verify: (_) {
        verify(mockAudioHandler.play()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PauseAudio should call audioHandler.pause',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.pauseAudio()),
      verify: (_) {
        verify(mockAudioHandler.pause()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'StopAudio should call audioHandler.stop',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.stopAudio()),
      verify: (_) {
        verify(mockAudioHandler.stop()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToNext should call audioHandler.skipToNext',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToNext()),
      verify: (_) {
        verify(mockAudioHandler.skipToNext()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToPrevious should call audioHandler.skipToPrevious',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToPrevious()),
      verify: (_) {
        verify(mockAudioHandler.skipToPrevious()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SeekTo should call audioHandler.seek',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) =>
          bloc.add(const AudioPlayerEvent.seekTo(Duration(seconds: 45))),
      verify: (_) {
        verify(mockAudioHandler.seek(const Duration(seconds: 45))).called(1);
      },
    );
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToQueueItem should call audioHandler.skipToQueueItem',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToQueueItem(1)),
      verify: (_) {
        verify(mockAudioHandler.skipToQueueItem(1)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PlayFromQueue should call audioHandler.playFromQueue',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.playFromQueue([], 0)),
      verify: (_) {
        verify(mockAudioHandler.playFromQueue([], 0)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateQueue should call audioHandler.updateQueue',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.updateQueue([])),
      verify: (_) {
        verify(mockAudioHandler.updateQueue([])).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'AddQueueItem should call audioHandler.addQueueItem',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.addQueueItem(MediaItem(id: 'add', title: 'Add')),
      ),
      verify: (_) {
        verify(
          mockAudioHandler.addQueueItem(
            const MediaItem(id: 'add', title: 'Add'),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'RemoveQueueItem should call audioHandler.removeQueueItem',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.removeQueueItem(
          MediaItem(id: 'remove', title: 'Remove'),
        ),
      ),
      verify: (_) {
        verify(
          mockAudioHandler.removeQueueItem(
            const MediaItem(id: 'remove', title: 'Remove'),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'MoveQueueItem should call audioHandler.moveQueueItem',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(const AudioPlayerEvent.moveQueueItem(0, 1)),
      verify: (_) {
        verify(mockAudioHandler.moveQueueItem(0, 1)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetRepeatMode should call audioHandler.setRepeatMode',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.setRepeatMode(AudioServiceRepeatMode.all),
      ),
      verify: (_) {
        verify(
          mockAudioHandler.setRepeatMode(AudioServiceRepeatMode.all),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetShuffleMode should call audioHandler.setShuffleMode',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.setShuffleMode(AudioServiceShuffleMode.all),
      ),
      verify: (_) {
        verify(
          mockAudioHandler.setShuffleMode(AudioServiceShuffleMode.all),
        ).called(1);
      },
    );
  });

  group('AudioPlayerBloc - Audio Control Events (State + Delegation)', () {
    setUp(() {
      // Seed with 0.5 (different from default 1.0) to ensure initialization emits a state
      // allowing us to deterministically skip it.
      // Seed speed with 1.0 (default) to likely avoid extra emission for speed logic in volume test.
      // Note: We need to handle each test carefully regarding seeds if they interfere,
      // but using 0.5 for both as base "different" value is a good start.
      // Actually, for SetVolume test: seed volume 0.5, speed 1.0.
      // For SetSpeed test: seed volume 1.0, speed 0.5.
      // But setUp is shared. So let's seed BOTH with 0.5 to be safe and explicits skips.
      volumeSubject = BehaviorSubject<double>.seeded(0.5);
      speedSubject = BehaviorSubject<double>.seeded(0.5);

      when(mockAudioHandler.volume).thenAnswer((_) => volumeSubject);
      when(mockAudioHandler.speed).thenAnswer((_) => speedSubject);

      when(mockAudioHandler.setVolume(any)).thenAnswer((invocation) async {
        final volume = invocation.positionalArguments[0] as double;
        volumeSubject.add(volume);
      });
      when(mockAudioHandler.setSpeed(any)).thenAnswer((invocation) async {
        final speed = invocation.positionalArguments[0] as double;
        speedSubject.add(speed);
      });
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetVolume should call audioHandler.setVolume and update state',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) async {
        await Future.delayed(
          Duration.zero,
        ); // Allow initialization events to process
        bloc.add(const AudioPlayerEvent.setVolume(0.8));
      },
      skip: 2, // Skip initialization emissions (volume 0.5, speed 0.5)
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.volume, 'volume', 0.8),
      ],
      verify: (_) {
        verify(mockAudioHandler.setVolume(0.8)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetSpeed should call audioHandler.setSpeed and update state',
      build: () => AudioPlayerBloc(mockAudioHandler),
      act: (bloc) async {
        await Future.delayed(
          Duration.zero,
        ); // Allow initialization events to process
        bloc.add(const AudioPlayerEvent.setSpeed(1.2));
      },
      skip: 2, // Skip initialization emissions (volume 0.5, speed 0.5)
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.speed, 'speed', 1.2),
      ],
      verify: (_) {
        verify(mockAudioHandler.setSpeed(1.2)).called(1);
      },
    );
  });
  group('AudioPlayerBloc - JSON Serialization Errors', () {
    test('fromJson should handle malformed queue data gracefully', () {
      final Map<String, Object> json = {
        'volume': 0.8,
        'speed': 1.2,
        'queue': ['invalid-data'], // Malformed queue list
        'queueIndex': 0,
      };

      final bloc = AudioPlayerBloc(mockAudioHandler);
      final AudioPlayerState? state = bloc.fromJson(json);

      expect(state, isNotNull);
      expect(state!.volume, 0.8);
      expect(state.speed, 1.2);
      expect(state.queueState, isNull); // Queue should be null due to error
    });

    test('fromJson should handle malformed position data gracefully', () {
      final Map<String, Object> json = {
        'volume': 0.8,
        'speed': 1.2,
        'position': 'invalid-position', // Should be int
      };

      final bloc = AudioPlayerBloc(mockAudioHandler);
      final AudioPlayerState? state = bloc.fromJson(json);

      expect(state, isNotNull);
      expect(state!.positionData, isNull); // Position should be null
    });

    test('fromJson should return initial state on general error', () {
      final json = {
        'volume': 'invalid-volume-string', // Causes CastError
      };

      final bloc = AudioPlayerBloc(mockAudioHandler);
      final AudioPlayerState? state = bloc.fromJson(json);

      expect(state, isNotNull);
      expect(state!.status, AudioPlayerStatus.initial); // Default fallback
      expect(state.volume, 1.0); // Default
    });
  });

  group('AudioPlayerBloc - LoadAudioPlayerData Errors', () {
    const mockQueueState = QueueState(
      queue: [MediaItem(id: '1', title: 'Test')],
      queueIndex: 0,
      repeatMode: AudioServiceRepeatMode.none,
      shuffleIndices: null,
    );
    const mockPositionData = PositionData(
      position: Duration(seconds: 10),
      bufferedPosition: Duration.zero,
      duration: Duration(minutes: 3),
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should catch error during queue restoration and continue',
      build: () {
        when(
          mockAudioHandler.queue,
        ).thenAnswer((_) => BehaviorSubject.seeded([]));
        when(
          mockAudioHandler.playFromQueue(any, any),
        ).thenThrow(Exception('Restoration failed'));
        // Mock fallback streams to successful values to ensure it continues
        when(
          mockAudioHandler.queueState,
        ).thenAnswer((_) => BehaviorSubject.seeded(mockQueueState));
        when(mockAudioHandler.playbackState).thenAnswer(
          (_) => BehaviorSubject.seeded(PlaybackState(queueIndex: 0)),
        );

        return AudioPlayerBloc(mockAudioHandler);
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.initial,
        queueState: mockQueueState,
        positionData: mockPositionData,
      ),
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
      verify: (_) {
        verify(mockAudioHandler.playFromQueue(any, any)).called(1);
        // Should verify that it moved on to fetching current state (implied if no crash)
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should handle timeouts/errors when fetching initial state from streams',
      build: () {
        when(
          mockAudioHandler.queue,
        ).thenAnswer((_) => BehaviorSubject.seeded([]));

        // Mock streams to never emit (timeout) or throw
        // Using unseeded subjects which will cause timeout in `.first.timeout()`
        when(
          mockAudioHandler.queueState,
        ).thenAnswer((_) => BehaviorSubject<QueueState>());
        when(
          mockAudioHandler.playbackState,
        ).thenAnswer((_) => BehaviorSubject<PlaybackState>());
        when(
          mockAudioHandler.mediaItem,
        ).thenAnswer((_) => BehaviorSubject<MediaItem?>());

        return AudioPlayerBloc(mockAudioHandler);
      },
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
      // Expect a state update with defaults/empty since all streams failed/timed out
      expect: () => [
        isA<AudioPlayerState>().having(
          (s) => s.status,
          'status',
          AudioPlayerStatus.success,
        ),
      ],
      wait: const Duration(seconds: 1), // Wait for timeouts
    );
  });
}
