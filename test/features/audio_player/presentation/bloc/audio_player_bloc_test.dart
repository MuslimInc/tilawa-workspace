import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
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
  late BehaviorSubject<double> volumeSubject;
  late BehaviorSubject<double> speedSubject;

  setUp(() {
    mockAudioHandler = MockAudioPlayerHandler();
    mediaItemSubject = BehaviorSubject<MediaItem?>();
    playbackStateSubject = BehaviorSubject<PlaybackState>();
    queueStateSubject = BehaviorSubject<QueueState>();
    volumeSubject = BehaviorSubject<double>.seeded(1.0);
    speedSubject = BehaviorSubject<double>.seeded(1.0);

    // Setup mock streams
    when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(
      mockAudioHandler.playbackState,
    ).thenAnswer((_) => playbackStateSubject);
    when(mockAudioHandler.queueState).thenAnswer((_) => queueStateSubject);
    when(mockAudioHandler.volume).thenAnswer((_) => volumeSubject);
    when(mockAudioHandler.speed).thenAnswer((_) => speedSubject);
  });

  tearDown(() {
    mediaItemSubject.close();
    playbackStateSubject.close();
    queueStateSubject.close();
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
}
