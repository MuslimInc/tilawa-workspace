import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/entities/audio_modes.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/shared/models/position_data.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'audio_player_bloc_test.mocks.dart';

@GenerateMocks([
  PlayAudioUseCase,
  PauseAudioUseCase,
  StopAudioUseCase,
  SeekToUseCase,
  SetVolumeUseCase,
  SetPlaybackSpeedUseCase,
  SetRepeatModeUseCase,
  SetShuffleModeUseCase,
  SkipToNextUseCase,
  SkipToPreviousUseCase,
  SkipToQueueItemUseCase,
  PlayFromQueueUseCase,
  UpdateQueueUseCase,
  AddQueueItemUseCase,
  RemoveQueueItemUseCase,
  MoveQueueItemUseCase,
  LoadAudioPlayerDataUseCase,
  GetAudioStreamsUseCase,
])
void main() {
  setUpAll(() async {
    provideDummy<Either<Failure, void>>(const Right(null));
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  late MockPlayAudioUseCase mockPlayAudio;
  late MockPauseAudioUseCase mockPauseAudio;
  late MockStopAudioUseCase mockStopAudio;
  late MockSeekToUseCase mockSeekTo;
  late MockSetVolumeUseCase mockSetVolume;
  late MockSetPlaybackSpeedUseCase mockSetPlaybackSpeed;
  late MockSkipToNextUseCase mockSkipToNext;
  late MockSkipToPreviousUseCase mockSkipToPrevious;
  late MockSkipToQueueItemUseCase mockSkipToQueueItem;
  late MockPlayFromQueueUseCase mockPlayFromQueue;
  late MockUpdateQueueUseCase mockUpdateQueue;
  late MockAddQueueItemUseCase mockAddQueueItem;
  late MockRemoveQueueItemUseCase mockRemoveQueueItem;
  late MockMoveQueueItemUseCase mockMoveQueueItem;
  late MockSetRepeatModeUseCase mockSetRepeatMode;
  late MockSetShuffleModeUseCase mockSetShuffleMode;
  late MockLoadAudioPlayerDataUseCase mockLoadAudioPlayerData;
  late MockGetAudioStreamsUseCase mockGetAudioStreams;

  late BehaviorSubject<AudioEntity?> currentAudioSubject;
  late BehaviorSubject<PlaybackStateEntity> playbackStateSubject;
  late BehaviorSubject<List<AudioEntity>> queueSubject;
  late BehaviorSubject<double> volumeSubject;
  late BehaviorSubject<double> speedSubject;
  late BehaviorSubject<Duration> positionSubject;

  setUp(() {
    mockPlayAudio = MockPlayAudioUseCase();
    mockPauseAudio = MockPauseAudioUseCase();
    mockStopAudio = MockStopAudioUseCase();
    mockSeekTo = MockSeekToUseCase();
    mockSetVolume = MockSetVolumeUseCase();
    mockSetPlaybackSpeed = MockSetPlaybackSpeedUseCase();
    mockSkipToNext = MockSkipToNextUseCase();
    mockSkipToPrevious = MockSkipToPreviousUseCase();
    mockSkipToQueueItem = MockSkipToQueueItemUseCase();
    mockPlayFromQueue = MockPlayFromQueueUseCase();
    mockUpdateQueue = MockUpdateQueueUseCase();
    mockAddQueueItem = MockAddQueueItemUseCase();
    mockRemoveQueueItem = MockRemoveQueueItemUseCase();
    mockMoveQueueItem = MockMoveQueueItemUseCase();
    mockSetRepeatMode = MockSetRepeatModeUseCase();
    mockSetShuffleMode = MockSetShuffleModeUseCase();
    mockLoadAudioPlayerData = MockLoadAudioPlayerDataUseCase();
    mockGetAudioStreams = MockGetAudioStreamsUseCase();

    currentAudioSubject = BehaviorSubject<AudioEntity?>();
    playbackStateSubject = BehaviorSubject<PlaybackStateEntity>();
    queueSubject = BehaviorSubject<List<AudioEntity>>.seeded([]);
    volumeSubject = BehaviorSubject<double>.seeded(1.0);
    speedSubject = BehaviorSubject<double>.seeded(1.0);
    positionSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

    // Setup mock streams
    when(
      mockGetAudioStreams.currentAudio,
    ).thenAnswer((_) => currentAudioSubject);
    when(
      mockGetAudioStreams.playbackState,
    ).thenAnswer((_) => playbackStateSubject);
    when(mockGetAudioStreams.queue).thenAnswer((_) => queueSubject);
    when(mockGetAudioStreams.volume).thenAnswer((_) => volumeSubject);
    when(mockGetAudioStreams.speed).thenAnswer((_) => speedSubject);
    when(mockGetAudioStreams.position).thenAnswer((_) => positionSubject);

    // Setup default mock returns for UseCases (ResultVoid/ResultFuture)
    // We can add these as needed in tests or set defaults here
  });

  tearDown(() {
    currentAudioSubject.close();
    playbackStateSubject.close();
    queueSubject.close();
    volumeSubject.close();
    speedSubject.close();
    positionSubject.close();
  });

  AudioPlayerBloc buildBloc() {
    return AudioPlayerBloc(
      mockGetAudioStreams,
      mockPlayAudio,
      mockPauseAudio,
      mockStopAudio,
      mockSeekTo,
      mockSkipToNext,
      mockSkipToPrevious,
      mockSetVolume,
      mockSetPlaybackSpeed,
      mockSetRepeatMode,
      mockSetShuffleMode,
      mockSkipToQueueItem,
      mockPlayFromQueue,
      mockUpdateQueue,
      mockAddQueueItem,
      mockRemoveQueueItem,
      mockMoveQueueItem,
      mockLoadAudioPlayerData,
    );
  }

  group('AudioPlayerBloc - LoadAudioPlayerData', () {
    test('initial state is correct', () {
      final AudioPlayerBloc bloc = buildBloc();
      expect(
        bloc.state,
        const AudioPlayerState(status: AudioPlayerStatus.initial),
      );
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - should emit loading then success',
      setUp: () {
        when(
          mockLoadAudioPlayerData(restorePlayback: anyNamed('restorePlayback')),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) {
        bloc.add(const AudioPlayerEvent.loadAudioPlayerData());
      },
      expect: () => [
        isA<AudioPlayerState>().having(
          (s) => s.status,
          'status',
          AudioPlayerStatus.loading,
        ),
        isA<AudioPlayerState>().having(
          (s) => s.status,
          'status',
          AudioPlayerStatus.success,
        ),
      ],
      verify: (_) {
        verify(mockLoadAudioPlayerData()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData - when restoration disabled, should call usecase with false',
      setUp: () {
        when(
          mockLoadAudioPlayerData(restorePlayback: anyNamed('restorePlayback')),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) {
        bloc.add(
          const AudioPlayerEvent.loadAudioPlayerData(restorePlayback: false),
        );
      },
      verify: (_) {
        verify(mockLoadAudioPlayerData(restorePlayback: false)).called(1);
      },
    );
  });

  group('AudioPlayerBloc - Stream Setup', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'stream setup - should emit state when currentAudio stream emits',
      setUp: () {
        const testAudio = AudioEntity(
          id: 'stream-test',
          title: 'Stream Test',
          url: 'url',
          duration: Duration(minutes: 3),
        );
        Future.delayed(const Duration(milliseconds: 50), () {
          currentAudioSubject.add(testAudio);
        });
      },
      build: () => buildBloc(),
      wait: const Duration(milliseconds: 200),
      skip: 1,
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.currentAudio, 'currentAudio', isNotNull)
            .having(
              (s) => s.currentAudio?.id,
              'currentAudio.id',
              'stream-test',
            ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'stream setup - should emit state when playbackState stream emits',
      setUp: () {
        const testPlaybackState = PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          duration: Duration.zero,
          currentIndex: 0,
          queue: [],
        );
        Future.delayed(const Duration(milliseconds: 50), () {
          playbackStateSubject.add(testPlaybackState);
        });
      },
      build: () => buildBloc(),
      wait: const Duration(milliseconds: 200),
      skip: 1,
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.playbackState, 'playbackState', isNotNull)
            .having((s) => s.playbackState?.isPlaying, 'isPlaying', true),
      ],
    );
  });

  group('AudioPlayerBloc - State Persistence', () {
    test('fromJson should return null', () {
      final AudioPlayerBloc bloc = buildBloc();
      expect(bloc.fromJson(<String, dynamic>{}), isNull);
    });

    test('toJson should return null', () {
      final AudioPlayerBloc bloc = buildBloc();
      expect(
        bloc.toJson(const AudioPlayerState(status: AudioPlayerStatus.initial)),
        isNull,
      );
    });
  });

  group('AudioPlayerBloc - State Update Events', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateAudio should update state with new audio entity',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateAudio(
          AudioEntity(
            id: 'new-id',
            title: 'New Title',
            url: 'url',
            duration: Duration.zero,
          ),
        ),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.currentAudio, 'currentAudio', isNotNull)
            .having((s) => s.currentAudio?.id, 'currentAudio.id', 'new-id'),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdatePlaybackStateEntity should update state with new playback state entity',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updatePlaybackStateEntity(
          PlaybackStateEntity(
            isPlaying: true,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            duration: Duration.zero,
            currentIndex: 0,
            queue: [],
          ),
        ),
      ),
      expect: () => [
        isA<AudioPlayerState>()
            .having((s) => s.playbackState, 'playbackState', isNotNull)
            .having((s) => s.playbackState?.isPlaying, 'isPlaying', true),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdatePositionData should update state with new position data',
      build: () => buildBloc(),
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
  });

  group('AudioPlayerBloc - State Update Events (Volume/Speed)', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateVolume should update state with new volume',
      build: () => buildBloc(),
      act: (bloc) async {
        await Future.delayed(Duration.zero);
        bloc.add(const AudioPlayerEvent.updateVolume(0.5));
      },
      skip: 1,
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.volume, 'volume', 0.5),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateSpeed should update state with new speed',
      build: () => buildBloc(),
      act: (bloc) async {
        await Future.delayed(Duration.zero);
        bloc.add(const AudioPlayerEvent.updateSpeed(1.5));
      },
      skip: 1,
      expect: () => [
        isA<AudioPlayerState>().having((s) => s.speed, 'speed', 1.5),
      ],
    );
  });

  group('AudioPlayerBloc - Audio Control Events (Command Delegation)', () {
    setUp(() {
      when(mockPlayAudio.call()).thenAnswer((_) async => const Right(null));
      when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      when(mockStopAudio.call()).thenAnswer((_) async => const Right(null));
      when(mockSkipToNext.call()).thenAnswer((_) async => const Right(null));
      when(
        mockSkipToPrevious.call(),
      ).thenAnswer((_) async => const Right(null));
      when(mockSeekTo.call(any)).thenAnswer((_) async => const Right(null));
      when(
        mockSkipToQueueItem.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockPlayFromQueue.call(any, any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockUpdateQueue.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockAddQueueItem.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockRemoveQueueItem.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockMoveQueueItem.call(any, any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockSetRepeatMode.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        mockSetShuffleMode.call(any),
      ).thenAnswer((_) async => const Right(null));
      when(mockSetVolume.call(any)).thenAnswer((_) async => const Right(null));
      when(
        mockSetPlaybackSpeed.call(any),
      ).thenAnswer((_) async => const Right(null));
    });

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PlayAudio should call mockPlayAudio',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.playAudio()),
      verify: (_) {
        verify(mockPlayAudio()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PauseAudio should call mockPauseAudio',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.pauseAudio()),
      verify: (_) {
        verify(mockPauseAudio()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'StopAudio should call mockStopAudio',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.stopAudio()),
      verify: (_) {
        verify(mockStopAudio()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToNext should call mockSkipToNext',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToNext()),
      verify: (_) {
        verify(mockSkipToNext()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToPrevious should call mockSkipToPrevious',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToPrevious()),
      verify: (_) {
        verify(mockSkipToPrevious()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SeekTo should call mockSeekTo',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AudioPlayerEvent.seekTo(Duration(seconds: 45))),
      verify: (_) {
        verify(mockSeekTo(const Duration(seconds: 45))).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SkipToQueueItem should call mockSkipToQueueItem',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.skipToQueueItem(1)),
      verify: (_) {
        verify(mockSkipToQueueItem(1)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PlayFromQueue should call mockPlayFromQueue',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.playFromQueue([], 0)),
      verify: (_) {
        verify(mockPlayFromQueue([], 0)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'UpdateQueue should call mockUpdateQueue',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.updateQueue([])),
      verify: (_) {
        verify(mockUpdateQueue([])).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'AddQueueItem should call mockAddQueueItem',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.addQueueItem(
          AudioEntity(
            id: 'add',
            title: 'Add',
            url: 'u',
            duration: Duration.zero,
          ),
        ),
      ),
      verify: (_) {
        verify(
          mockAddQueueItem(
            const AudioEntity(
              id: 'add',
              title: 'Add',
              url: 'u',
              duration: Duration.zero,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'RemoveQueueItem should call mockRemoveQueueItem',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.removeQueueItem(
          AudioEntity(
            id: 'remove',
            title: 'Remove',
            url: 'u',
            duration: Duration.zero,
          ),
        ),
      ),
      verify: (_) {
        verify(
          mockRemoveQueueItem(
            const AudioEntity(
              id: 'remove',
              title: 'Remove',
              url: 'u',
              duration: Duration.zero,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'MoveQueueItem should call mockMoveQueueItem',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.moveQueueItem(0, 1)),
      verify: (_) {
        verify(mockMoveQueueItem(0, 1)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetRepeatMode should call mockSetRepeatMode',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AudioPlayerEvent.setRepeatMode(AudioRepeatMode.all)),
      verify: (_) {
        verify(mockSetRepeatMode(AudioRepeatMode.all)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetShuffleMode should call mockSetShuffleMode',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AudioPlayerEvent.setShuffleMode(AudioShuffleMode.all)),
      verify: (_) {
        verify(mockSetShuffleMode(AudioShuffleMode.all)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetVolume should call mockSetVolume',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.setVolume(0.5)),
      verify: (_) {
        verify(mockSetVolume(0.5)).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetSpeed should call mockSetPlaybackSpeed',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.setSpeed(1.5)),
      verify: (_) {
        verify(mockSetPlaybackSpeed(1.5)).called(1);
      },
    );
  });
}
