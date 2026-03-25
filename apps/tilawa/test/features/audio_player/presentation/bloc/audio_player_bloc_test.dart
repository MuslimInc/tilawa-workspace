import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/add_or_update_history_use_case.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

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
  AddOrUpdateHistoryUseCase,
  AnalyticsService,
])
void main() {
  setUpAll(() async {
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, HistoryEntity>>(
      Right(
        HistoryEntity(
          id: 'dummy',
          surahId: 1,
          surahName: 'dummy',
          surahNameEn: 'dummy',
          reciterId: 'dummy',
          reciterName: 'dummy',
          moshafId: 1,
          moshafName: 'dummy',
          lastPositionMs: 0,
          durationMs: 0,
          audioUrl: 'dummy',
          playedAt: DateTime(2023),
        ),
      ),
    );
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
  late MockAddOrUpdateHistoryUseCase mockAddOrUpdateHistory;
  late MockAnalyticsService mockAnalyticsService;

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
    mockSettingsCubit = MockSettingsCubit();
    mockCheckAudioPlayability = MockCheckAudioPlayabilityUseCase();
    mockAddOrUpdateHistory = MockAddOrUpdateHistoryUseCase();
    mockAnalyticsService = MockAnalyticsService();

    currentAudioSubject = BehaviorSubject<AudioEntity?>();
    playbackStateSubject = BehaviorSubject<PlaybackStateEntity>();
    queueSubject = BehaviorSubject<List<AudioEntity>>.seeded([]);
    volumeSubject = BehaviorSubject<double>.seeded(1.0);
    speedSubject = BehaviorSubject<double>.seeded(1.0);
    positionSubject = BehaviorSubject<Duration>();

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

    // Setup Mock Analytics
    when(
      mockAnalyticsService.logAudioPlay(
        any,
        audioName: anyNamed('audioName'),
        artist: anyNamed('artist'),
        surahName: anyNamed('surahName'),
        reciterName: anyNamed('reciterName'),
        moshafName: anyNamed('moshafName'),
        surahId: anyNamed('surahId'),
        reciterId: anyNamed('reciterId'),
      ),
    ).thenAnswer((_) async {
      return;
    });

    // Setup default SettingsCubit state
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      mockSettingsCubit.isSleepTimerEnabledStream,
    ).thenAnswer((_) => const Stream<bool>.empty());

    // Default mock return for AddOrUpdateHistory
    when(
      mockAddOrUpdateHistory.call(
        surahId: anyNamed('surahId'),
        surahName: anyNamed('surahName'),
        surahNameEn: anyNamed('surahNameEn'),
        reciterId: anyNamed('reciterId'),
        reciterName: anyNamed('reciterName'),
        moshafId: anyNamed('moshafId'),
        moshafName: anyNamed('moshafName'),
        lastPositionMs: anyNamed('lastPositionMs'),
        durationMs: anyNamed('durationMs'),
        audioUrl: anyNamed('audioUrl'),
        artworkUrl: anyNamed('artworkUrl'),
        completed: anyNamed('completed'),
      ),
    ).thenAnswer(
      (_) async => Right(
        HistoryEntity(
          id: '1',
          surahId: 1,
          surahName: 'test',
          surahNameEn: 'test',
          reciterId: '1',
          reciterName: 'test',
          moshafId: 1,
          moshafName: 'test',
          lastPositionMs: 0,
          durationMs: 0,
          audioUrl: 'test',
          playedAt: DateTime(2023),
        ),
      ),
    );
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
      mockAddOrUpdateHistory,
      mockAnalyticsService,
    );
  }

  // ... (previous tests) ...
  // Re-adding previous tests here would be verbose, assume they are there in real file.
  // I will append the History Saving tests.

  group('AudioPlayerBloc - History Saving', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should emit PositionData immediately when currentAudio changes (initial sync)',
      build: () => buildBloc(),
      act: (bloc) async {
        const audio = AudioEntity(
          id: 'initial-sync',
          title: 'Initial Sync',
          url: 'url',
          duration: Duration(minutes: 3),
        );
        // We add the audio
        bloc.add(const AudioPlayerEvent.updateAudio(audio));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        // 1. UpdateAudio state
        isA<AudioPlayerState>().having((s) => s.currentAudio?.id, 'audioId', 'initial-sync'),
        // 2. IMMEDIATE UpdatePositionData state (triggered by _emitPositionDataUpdate)
        isA<AudioPlayerState>().having((s) => s.positionData?.duration, 'initialDuration', const Duration(minutes: 3)),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should emit PositionData immediately when playbackState duration is discovered',
      build: () => buildBloc(),
      act: (bloc) async {
        const zeroAudio = AudioEntity(
          id: 'discovery',
          title: 'Discovery',
          url: 'url',
          duration: Duration.zero,
        );
        bloc.add(const AudioPlayerEvent.updateAudio(zeroAudio));
        await Future.delayed(Duration.zero);

        final discoveredState = PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: const Duration(seconds: 45),
          currentIndex: 0,
          queue: const [zeroAudio],
        );
        
        // This should trigger immediate PositionData update with the new duration
        bloc.add(AudioPlayerEvent.updatePlaybackStateEntity(discoveredState));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        // From updateAudio
        isA<AudioPlayerState>().having((s) => s.currentAudio?.id, 'audioId', 'discovery'),
        // From _emitPositionDataUpdate after updateAudio (duration 0)
        isA<AudioPlayerState>().having((s) => s.positionData?.duration, 'initialZeroDuration', Duration.zero),
        // From updatePlaybackStateEntity
        isA<AudioPlayerState>().having((s) => s.playbackState?.duration, 'discoveredDuration', const Duration(seconds: 45)),
        // From _emitPositionDataUpdate after updatePlaybackStateEntity (duration 45s!)
        isA<AudioPlayerState>().having((s) => s.positionData?.duration, 'syncedDuration', const Duration(seconds: 45)),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'positionData duration should use playbackState duration if currentAudio duration is zero',
      build: () => buildBloc(),
      act: (bloc) async {
        const zeroDurationAudio = AudioEntity(
          id: '1',
          title: 'Test',
          url: 'url',
          duration: Duration.zero,
        );
        final playbackState = PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: const Duration(minutes: 5),
          currentIndex: 0,
          queue: const [zeroDurationAudio],
        );

        // 1. Set current audio (duration 0)
        bloc.add(const AudioPlayerEvent.updateAudio(zeroDurationAudio));
        await Future.delayed(Duration.zero);

        // 2. Set playback state (duration 5 min)
        bloc.add(AudioPlayerEvent.updatePlaybackStateEntity(playbackState));
        await Future.delayed(Duration.zero);

        // 3. Trigger position update (this used to use currentAudio.duration)
        // In the bloc, we now check playbackState.duration if audio.duration is zero.
        positionSubject.add(const Duration(seconds: 10));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        // 1. UpdateAudio
        isA<AudioPlayerState>().having((s) => s.currentAudio?.id, 'audioId', '1'),
        // 2. IMMEDIATE UpdatePositionData after UpdateAudio
        isA<AudioPlayerState>().having((s) => s.positionData?.duration, 'initialDuration', Duration.zero),
        // 3. UpdatePlaybackState
        isA<AudioPlayerState>().having((s) => s.playbackState?.duration, 'playbackDuration', const Duration(minutes: 5)),
        // 4. IMMEDIATE UpdatePositionData after UpdatePlaybackState (fixed duration!)
        isA<AudioPlayerState>().having((s) => s.positionData?.duration, 'syncedDuration', const Duration(minutes: 5)),
        // 5. UpdatePositionData from positionSubject
        isA<AudioPlayerState>().having((s) => s.positionData?.position, 'position', const Duration(seconds: 10)),
      ],
    );

    const historyAudio = AudioEntity(
      id: 'history-audio-1',
      title: 'History Test',
      url: 'url',
      duration: Duration(minutes: 5),
      artist: 'Reciter Name',
      album: 'Moshaf Name',
      extras: {'reciterId': '123', 'moshafId': 456, 'surahId': 789},
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history with 0 duration if AudioEntity has 0 duration, ignoring PlaybackState duration',
      setUp: () {
        // Seed playback state with "stale" duration
        playbackStateSubject.add(
          PlaybackStateEntity(
            isPlaying: true,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration(seconds: 10),
            bufferedPosition: Duration(seconds: 20),
            duration: Duration(minutes: 10), // Stale duration
            currentIndex: 0,
            queue: [],
          ),
        );
      },
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateAudio(
          AudioEntity(
            id: 'zero-duration-audio',
            title: 'Zero Duration Test',
            url: 'url',
            duration: Duration.zero, // Zero duration
            artist: 'Reciter',
            album: 'Moshaf',
            extras: {'reciterId': '1', 'moshafId': 2, 'surahId': 3},
          ),
        ),
      ),
      verify: (_) {
        // Should NOT save history when audio is first set
        verifyNever(
          mockAddOrUpdateHistory.call(
            surahId: anyNamed('surahId'),
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        );
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history for PREVIOUS audio when audio updates (track transition)',
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio, // The track causing the transition
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateAudio(
          AudioEntity(
            id: 'next-audio',
            title: 'Next Audio',
            url: 'url',
            duration: Duration(minutes: 10),
            artist: 'Reciter',
            album: 'Moshaf',
            extras: {'reciterId': '1', 'moshafId': 2, 'surahId': 3},
          ),
        ),
      ),
      verify: (_) {
        // Should save existing (previous) audio only
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789, // historyAudio surahId
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        ).called(1);

        // Should NOT save new audio (it hasn't been played yet)
        verifyNever(
          mockAddOrUpdateHistory.call(
            surahId: 3, // next audio surahId
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        );
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should NOT save history when audio is first set (not played yet)',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.updateAudio(historyAudio)),
      verify: (_) {
        // Should NOT save history until the audio is actually played
        verifyNever(
          mockAddOrUpdateHistory.call(
            surahId: anyNamed('surahId'),
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        );
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should NOT save history when extras are missing',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(
        const AudioPlayerEvent.updateAudio(
          AudioEntity(
            id: 'no-extras',
            title: 'No Extras',
            url: 'url',
            duration: Duration.zero,
          ),
        ),
      ),
      verify: (_) {
        verifyNever(
          mockAddOrUpdateHistory.call(
            surahId: anyNamed('surahId'),
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        );
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history when paused manually',
      setUp: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio,
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.pauseAudio()),
      verify: (_) {
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: 'History Test',
            surahNameEn: 'History Test',
            reciterId: '123',
            reciterName: 'Reciter Name',
            moshafId: 456,
            moshafName: 'Moshaf Name',
            lastPositionMs: 0,
            durationMs: 300000,
            audioUrl: 'url',
            artworkUrl: null,
            completed: false, // Default
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history when stopped',
      setUp: () {
        when(mockStopAudio.call()).thenAnswer((_) async => const Right(null));
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio,
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.stopAudio()),
      verify: (_) {
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: 'History Test',
            surahNameEn: 'History Test',
            reciterId: '123',
            reciterName: 'Reciter Name',
            moshafId: 456,
            moshafName: 'Moshaf Name',
            lastPositionMs: 0,
            durationMs: 300000,
            audioUrl: 'url',
            artworkUrl: null,
            completed: false,
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history when sleep timer expires',
      setUp: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      seed: () => AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio,
        sleepTimerTargetTime: DateTime.now().add(Duration(minutes: 15)),
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AudioPlayerEvent.audioTimerExpired()),
      expect: () => [
        isA<AudioPlayerState>().having(
          (s) => s.sleepTimerTargetTime,
          'sleepTimerTargetTime',
          isNull,
        ),
      ],
      verify: (_) {
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: 'History Test',
            surahNameEn: 'History Test',
            reciterId: '123',
            reciterName: 'Reciter Name',
            moshafId: 456,
            moshafName: 'Moshaf Name',
            lastPositionMs: 0,
            durationMs: 300000,
            audioUrl: 'url',
            artworkUrl: null,
            completed: false, // Default for pause/timer
          ),
        ).called(1);
      },
    );
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'saves history with last valid position when switching tracks (reproduction)',
      setUp: () {
        // Define test entities
        final testHistoryEntity = HistoryEntity(
          id: '1',
          surahId: 789,
          surahName: 'History Test',
          surahNameEn: 'History Test',
          reciterId: '123',
          reciterName: 'Reciter Name',
          moshafId: 456,
          moshafName: 'Moshaf Name',
          lastPositionMs: 50000,
          durationMs: 300000,
          audioUrl: 'url',
          playedAt: DateTime.now(),
        );

        // Ensure playback state subject has initial value
        if (!playbackStateSubject.hasValue) {
          playbackStateSubject.add(
            const PlaybackStateEntity(
              isPlaying: true,
              processingState: AudioProcessingStateStatus.ready,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration(minutes: 5),
              currentIndex: 0,
              queue: [],
            ),
          );
        }

        when(
          mockAddOrUpdateHistory(
            surahId: anyNamed('surahId'),
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: anyNamed('lastPositionMs'),
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        ).thenAnswer((_) async => Right(testHistoryEntity));
      },
      build: () => buildBloc(),
      act: (bloc) async {
        const historyAudio = AudioEntity(
          id: '1',
          title: 'History Test',
          url: 'url',
          duration: Duration(minutes: 5),
          extras: <String, dynamic>{
            'surahId': 789,
            'reciterId': '123',
            'moshafId': 456,
          },
        );
        const audio2 = AudioEntity(
          id: '2',
          title: '2',
          url: 'url',
          duration: Duration(minutes: 5),
          extras: <String, dynamic>{
            'surahId': 790,
            'reciterId': '123',
            'moshafId': 456,
          },
        );

        // 1. Set current audio
        currentAudioSubject.add(historyAudio);
        await Future.delayed(Duration.zero);

        // 2. Update positions properly (simulating playback)
        positionSubject.add(const Duration(seconds: 10));
        await Future.delayed(Duration.zero);
        positionSubject.add(const Duration(seconds: 50));
        await Future.delayed(Duration.zero);

        // 3. Reset position (simulating player switch / next track start)
        positionSubject.add(Duration.zero);
        await Future.delayed(Duration.zero);

        // 4. Switch audio
        currentAudioSubject.add(audio2);
        await Future.delayed(Duration.zero);
      },
      verify: (_) {
        // The cache works correctly! Looking at the debug output:
        // 1. Initial save: lastPositionMs: 0 (when audio is first set)
        // 2. Track switch save: lastPositionMs: 50000 (cached position retrieved!)
        // 3. New audio save: lastPositionMs: 0 (for audio2)
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: 'History Test',
            surahNameEn: 'History Test',
            reciterId: '123',
            reciterName: '', // Empty because AudioEntity has no artist field
            moshafId: 456,
            moshafName: '', // Empty because AudioEntity has no album field
            // CRITICAL: We expect ~50s (50000ms), NOT 0
            lastPositionMs: 50000,
            durationMs: 300000,
            audioUrl: 'url',
            artworkUrl: null,
            completed: false,
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history when skipping to next track',
      setUp: () {
        when(mockSkipToNext.call()).thenAnswer((_) async => const Right(null));
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio,
      ),
      build: () => buildBloc(),
      act: (bloc) async {
        // Simulate position updates
        positionSubject.add(const Duration(minutes: 2, seconds: 30));
        await Future.delayed(Duration.zero);
        // User presses "Next" button
        bloc.add(const AudioPlayerEvent.skipToNext());
        await Future.delayed(Duration.zero);
      },
      verify: (_) {
        // Should save current track's history before skipping
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: 150000, // 2:30 = 150 seconds = 150000ms
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'should save history when skipping to previous track',
      setUp: () {
        when(
          mockSkipToPrevious.call(),
        ).thenAnswer((_) async => const Right(null));
      },
      seed: () => const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: historyAudio,
      ),
      build: () => buildBloc(),
      act: (bloc) async {
        // Simulate position updates
        positionSubject.add(const Duration(minutes: 1, seconds: 45));
        await Future.delayed(Duration.zero);
        // User presses "Previous" button
        bloc.add(const AudioPlayerEvent.skipToPrevious());
        await Future.delayed(Duration.zero);
      },
      verify: (_) {
        // Should save current track's history before skipping
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 789,
            surahName: anyNamed('surahName'),
            surahNameEn: anyNamed('surahNameEn'),
            reciterId: anyNamed('reciterId'),
            reciterName: anyNamed('reciterName'),
            moshafId: anyNamed('moshafId'),
            moshafName: anyNamed('moshafName'),
            lastPositionMs: 105000, // 1:45 = 105 seconds = 105000ms
            durationMs: anyNamed('durationMs'),
            audioUrl: anyNamed('audioUrl'),
            artworkUrl: anyNamed('artworkUrl'),
            completed: anyNamed('completed'),
          ),
        ).called(1);
      },
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'uses playback state duration when audio metadata duration is missing',
      setUp: () {
        when(mockPauseAudio.call()).thenAnswer((_) async => const Right(null));
      },
      build: () => buildBloc(),
      act: (bloc) async {
        const zeroDurationAudio = AudioEntity(
          id: 'zero-duration',
          title: 'Zero Duration',
          url: 'url',
          duration: Duration.zero,
          artist: 'Reciter',
          album: 'Moshaf',
          extras: {'reciterId': '1', 'moshafId': 2, 'surahId': 3},
        );

        final playbackState = PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: const Duration(seconds: 5),
          bufferedPosition: const Duration(seconds: 5),
          duration: const Duration(seconds: 34),
          currentIndex: 0,
          queue: const [zeroDurationAudio],
        );

        currentAudioSubject.add(zeroDurationAudio);
        await Future.delayed(Duration.zero);
        playbackStateSubject.add(playbackState);
        await Future.delayed(Duration.zero);
        positionSubject.add(const Duration(seconds: 34));
        await Future.delayed(Duration.zero);

        bloc.add(const AudioPlayerEvent.pauseAudio());
        await Future.delayed(Duration.zero);
      },
      verify: (_) {
        verify(
          mockAddOrUpdateHistory.call(
            surahId: 3,
            surahName: 'Zero Duration',
            surahNameEn: 'Zero Duration',
            reciterId: '1',
            reciterName: 'Reciter',
            moshafId: 2,
            moshafName: 'Moshaf',
            lastPositionMs: 34000,
            durationMs: 34000,
            audioUrl: 'url',
            artworkUrl: null,
            completed: true,
          ),
        ).called(1);
      },
    );
  });

  test(
    'skipToNext waits for history to be saved before invoking SkipToNext use case',
    () async {
      when(mockSkipToNext.call()).thenAnswer((_) async => const Right(null));
      final completer = Completer<void>();
      final historyResponse = HistoryEntity(
        id: 'completion',
        surahId: 789,
        surahName: 'History Test',
        surahNameEn: 'History Test',
        reciterId: '123',
        reciterName: 'Reciter Name',
        moshafId: 456,
        moshafName: 'Moshaf Name',
        lastPositionMs: 0,
        durationMs: 300000,
        audioUrl: 'url',
        playedAt: DateTime.now(),
      );

      when(
        mockAddOrUpdateHistory.call(
          surahId: anyNamed('surahId'),
          surahName: anyNamed('surahName'),
          surahNameEn: anyNamed('surahNameEn'),
          reciterId: anyNamed('reciterId'),
          reciterName: anyNamed('reciterName'),
          moshafId: anyNamed('moshafId'),
          moshafName: anyNamed('moshafName'),
          lastPositionMs: anyNamed('lastPositionMs'),
          durationMs: anyNamed('durationMs'),
          audioUrl: anyNamed('audioUrl'),
          artworkUrl: anyNamed('artworkUrl'),
          completed: anyNamed('completed'),
        ),
      ).thenAnswer((_) async {
        await completer.future;
        return Right(historyResponse);
      });

      final bloc = buildBloc();
      const skipAudio = AudioEntity(
        id: 'history-audio-1',
        title: 'History Test',
        url: 'url',
        duration: Duration(minutes: 5),
        artist: 'Reciter Name',
        album: 'Moshaf Name',
        extras: {'reciterId': '123', 'moshafId': 456, 'surahId': 789},
      );

      bloc.add(const AudioPlayerEvent.updateAudio(skipAudio));
      await Future.delayed(Duration.zero);
      positionSubject.add(const Duration(seconds: 5));
      await Future.delayed(Duration.zero);

      bloc.add(const AudioPlayerEvent.skipToNext());

      // Allow event loop to process the awaiting _saveHistory call
      await Future.delayed(const Duration(milliseconds: 50));
      verifyNever(mockSkipToNext.call());

      completer.complete();
      await Future.delayed(const Duration(milliseconds: 10));

      verify(mockSkipToNext.call()).called(1);
      await bloc.close();
    },
  );
}
