import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/entities/audio_modes.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
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
  SettingsCubit,
  CheckAudioPlayabilityUseCase,
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
  late MockSettingsCubit mockSettingsCubit;
  late MockCheckAudioPlayabilityUseCase mockCheckAudioPlayability;

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
    positionSubject = BehaviorSubject<Duration>();
    mockGetAudioStreams = MockGetAudioStreamsUseCase();
    mockSettingsCubit = MockSettingsCubit();
    mockCheckAudioPlayability = MockCheckAudioPlayabilityUseCase();

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

    // Setup default SettingsCubit state
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());

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
      mockCheckAudioPlayability,
      mockSettingsCubit,
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

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData should restore active sleep timer if target is in future',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.initial,
        sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 5)),
      ),
      setUp: () {
        when(
          mockLoadAudioPlayerData(restorePlayback: anyNamed('restorePlayback')),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
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
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData should trigger expiration if target is in past',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.initial,
        sleepTimerTargetTime: DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
      ),
      setUp: () {
        when(
          mockLoadAudioPlayerData(restorePlayback: anyNamed('restorePlayback')),
        ).thenAnswer((_) async => const Right(null));
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
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
        isA<AudioPlayerState>().having(
          (s) => s.sleepTimerTargetTime,
          'sleepTimerTargetTime',
          isNull,
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'loadAudioPlayerData should trigger and wait for expiration if target is in near future',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.initial,
        sleepTimerTargetTime: DateTime.now().add(
          const Duration(milliseconds: 100),
        ),
      ),
      setUp: () {
        when(
          mockLoadAudioPlayerData(restorePlayback: anyNamed('restorePlayback')),
        ).thenAnswer((_) async => const Right(null));
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.loadAudioPlayerData()),
      wait: const Duration(milliseconds: 200),
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
        isA<AudioPlayerState>().having(
          (s) => s.sleepTimerTargetTime,
          'sleepTimerTargetTime',
          isNull,
        ),
      ],
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
          bufferedPosition: Duration.zero,
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
    test('fromJson should return correct state', () {
      final AudioPlayerBloc bloc = buildBloc();
      final AudioPlayerState? state = bloc.fromJson(<String, dynamic>{
        'status': 'success',
        'volume': 0.8,
      });
      expect(state?.status, AudioPlayerStatus.success);
      expect(state?.volume, 0.8);
    });

    test('toJson should return correct json', () {
      final AudioPlayerBloc bloc = buildBloc();
      final Map<String, dynamic>? json = bloc.toJson(
        const AudioPlayerState(status: AudioPlayerStatus.success, volume: 0.7),
      );
      expect(json?['status'], 'success');
      expect(json?['volume'], 0.7);
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
            bufferedPosition: Duration.zero,
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

    test(
      'Position stream listener should handle null currentAudio and playbackState (coverage)',
      () async {
        final AudioPlayerBloc bloc = buildBloc();
        // Ensure state has nulls
        expect(bloc.state.currentAudio, isNull);
        expect(bloc.state.playbackState, isNull);

        const position = Duration(seconds: 5);

        // Start listening to the stream BEFORE adding the value
        final Future<void> expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<AudioPlayerState>().having(
              (s) => s.positionData?.position,
              'position',
              position,
            ),
          ),
        );

        positionSubject.add(position);

        await expectation;
      },
    );

    test(
      'Position stream listener should handle non-null currentAudio and playbackState (coverage)',
      () async {
        const testAudio = AudioEntity(
          id: 'test-id',
          title: 'Test Title',
          url: 'url',
          duration: Duration(minutes: 5),
        );
        const testPlayback = PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration(seconds: 30),
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        );

        final AudioPlayerBloc bloc = buildBloc();

        // Seed with audio and playback state
        bloc.emit(
          bloc.state.copyWith(
            currentAudio: testAudio,
            playbackState: testPlayback,
          ),
        );

        const position = Duration(seconds: 10);
        final Future<void> expectation = expectLater(
          bloc.stream,
          emitsThrough(
            isA<AudioPlayerState>().having(
              (s) => s.positionData?.position,
              'position',
              position,
            ),
          ),
        );

        positionSubject.add(position);

        await expectation;

        // Verify that duration and buffered position were correctly taken from non-null state
        expect(bloc.state.positionData?.duration, testAudio.duration);
        expect(
          bloc.state.positionData?.bufferedPosition,
          testPlayback.bufferedPosition,
        );
      },
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
      // Default to allowing playback
      when(
        mockCheckAudioPlayability.call(any),
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
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.playFromQueue([
          AudioEntity(id: '1', title: 't', url: 'u', duration: Duration.zero),
        ], 0),
      ),
      verify: (_) {
        verify(
          mockPlayFromQueue([
            const AudioEntity(
              id: '1',
              title: 't',
              url: 'u',
              duration: Duration.zero,
            ),
          ], 0),
        ).called(1);
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

  group('AudioPlayerBloc - Sleep Timer', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'SetSleepTimer should update sleepTimerTargetTime',
      build: () => buildBloc(),
      act: (bloc) =>
          bloc.add(const AudioPlayerEvent.setSleepTimer(Duration(minutes: 15))),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNotNull,
            )
            .having((s) => s.isSleepTimerActive, 'isSleepTimerActive', true),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'CancelSleepTimer should set sleepTimerTargetTime to null',
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
      ).copyWith(sleepTimerTargetTime: DateTime.now()),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.cancelSleepTimer()),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having((s) => s.isSleepTimerActive, 'isSleepTimerActive', false),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'AudioTimerExpired should pause audio but preserve timer preference',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        lastSleepTimerDuration: const Duration(minutes: 15),
        sleepTimerTargetTime: DateTime.now().add(const Duration(seconds: 1)),
      ),
      build: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AudioPlayerEvent.audioTimerExpired()),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having(
              (s) => s.lastSleepTimerDuration,
              'lastSleepTimerDuration',
              const Duration(minutes: 15),
            ),
      ],
      verify: (_) {
        verify(mockPauseAudio()).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PlayAudio should start timer if lastSleepTimerDuration is set and enabled',
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        lastSleepTimerDuration: Duration(minutes: 10),
      ),
      setUp: () {
        when(mockPlayAudio.call()).thenAnswer((_) async => const Right(null));
        when(mockSettingsCubit.state).thenReturn(const SettingsState());
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.playAudio()),
      expect: () => [
        isA<AudioPlayerState>().having(
          (s) => s.isSleepTimerActive,
          'isSleepTimerActive',
          true,
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'PauseAudio should cancel active timer but preserve preference',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 5)),
        lastSleepTimerDuration: const Duration(minutes: 10),
      ),
      setUp: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.pauseAudio()),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having(
              (s) => s.lastSleepTimerDuration,
              'lastSleepTimerDuration',
              const Duration(minutes: 10),
            ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'StopAudio should cancel active timer but preserve preference',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 5)),
        lastSleepTimerDuration: const Duration(minutes: 10),
      ),
      setUp: () {
        when(mockStopAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.stopAudio()),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having(
              (s) => s.lastSleepTimerDuration,
              'lastSleepTimerDuration',
              const Duration(minutes: 10),
            ),
        isA<AudioPlayerState>().having(
          (s) => s.lastSleepTimerDuration,
          'lastSleepTimerDuration',
          const Duration(minutes: 10),
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'CancelSleepTimer with clearPreference true should reset preference',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 5)),
        lastSleepTimerDuration: const Duration(minutes: 10),
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.cancelSleepTimer()),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having(
              (s) => s.lastSleepTimerDuration,
              'lastSleepTimerDuration',
              isNull,
            ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'disabling sleep timer in settings should cancel active timer and reset preference',
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        sleepTimerTargetTime: DateTime.now().add(const Duration(minutes: 5)),
        lastSleepTimerDuration: const Duration(minutes: 10),
      ),
      setUp: () {
        final settingsStream = BehaviorSubject<SettingsState>.seeded(
          const SettingsState(),
        );
        when(mockSettingsCubit.stream).thenAnswer((_) => settingsStream);
        // Delay emitting the disabled state to occur after bloc initialization
        Future.delayed(const Duration(milliseconds: 50), () {
          settingsStream.add(const SettingsState(isSleepTimerEnabled: false));
        });
      },
      build: () => buildBloc(),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<AudioPlayerState>()
            .having(
              (s) => s.sleepTimerTargetTime,
              'sleepTimerTargetTime',
              isNull,
            )
            .having(
              (s) => s.lastSleepTimerDuration,
              'lastSleepTimerDuration',
              isNull,
            ),
      ],
    );
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'setSleepTimer should trigger expiration after duration',
      setUp: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.setSleepTimer(Duration(milliseconds: 100)),
      ),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<AudioPlayerState>().having(
          (s) => s.isSleepTimerActive,
          'isSleepTimerActive',
          true,
        ),
        isA<AudioPlayerState>().having(
          (s) => s.isSleepTimerActive,
          'isSleepTimerActive',
          false,
        ),
      ],
    );
  });
}
