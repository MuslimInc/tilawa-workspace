import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/audio_player/domain/entities/active_playback_snapshot.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/get_audio_streams_use_case.dart';
import 'package:tilawa/features/audio_player/domain/usecases/sync_active_playback_from_handler_use_case.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/add_or_update_history_use_case.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import 'audio_player_bloc_sync_active_playback_test.mocks.dart';

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
  SyncActivePlaybackFromHandlerUseCase,
  SettingsCubit,
  CheckAudioPlayabilityUseCase,
  AddOrUpdateHistoryUseCase,
  AnalyticsService,
  AppReviewTriggerManager,
])
void main() {
  setUpAll(() async {
    AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = false;
    AudioPlayerBloc.playbackReconciliationDebounce = const Duration(
      milliseconds: 30,
    );
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, ActivePlaybackSnapshot?>>(
      const Right(null),
    );
    provideDummy<Either<Failure, HistoryEntity>>(
      Right(
        HistoryEntity(
          id: 'h',
          surahId: 1,
          surahName: 's',
          surahNameEn: 's',
          reciterId: 'r',
          reciterName: 'r',
          moshafId: 1,
          moshafName: 'm',
          lastPositionMs: 0,
          durationMs: 0,
          audioUrl: 'u',
          playedAt: DateTime(2024),
        ),
      ),
    );
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = true;
    AudioPlayerBloc.playbackReconciliationDebounce = const Duration(
      milliseconds: 150,
    );
    await clearHydratedStorageForTest();
  });

  const AudioEntity hydratedSurah = AudioEntity(
    id: '1',
    title: 'Al-Fatiha',
    url: 'https://example.com/1.mp3',
    duration: Duration(minutes: 1),
  );

  const AudioEntity handlerSurah = AudioEntity(
    id: '2',
    title: 'Al-Baqarah',
    url: 'https://example.com/2.mp3',
    duration: Duration(hours: 1),
    artist: 'Akram Al-Alaqmi',
  );

  final PlaybackStateEntity handlerPlayback = PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: const Duration(minutes: 3),
    bufferedPosition: const Duration(minutes: 10),
    duration: const Duration(hours: 1),
    currentIndex: 0,
    queue: <AudioEntity>[handlerSurah],
    queueGeneration: 2,
  );

  late MockGetAudioStreamsUseCase mockGetAudioStreams;
  late MockSeekToUseCase mockSeekTo;
  late MockSyncActivePlaybackFromHandlerUseCase mockSyncActivePlayback;
  late MockSettingsCubit mockSettingsCubit;
  late MockAppReviewTriggerManager mockAppReviewTriggerManager;
  late MockAddOrUpdateHistoryUseCase mockAddOrUpdateHistory;
  late BehaviorSubject<AudioEntity?> currentAudioSubject;
  late BehaviorSubject<PlaybackStateEntity> playbackStateSubject;
  late BehaviorSubject<List<AudioEntity>> queueSubject;
  late BehaviorSubject<double> volumeSubject;
  late BehaviorSubject<double> speedSubject;
  late BehaviorSubject<Duration> positionSubject;

  AudioPlayerBloc buildBloc() {
    return AudioPlayerBloc(
      mockGetAudioStreams,
      MockPlayAudioUseCase(),
      MockPauseAudioUseCase(),
      MockStopAudioUseCase(),
      mockSeekTo,
      MockSkipToNextUseCase(),
      MockSkipToPreviousUseCase(),
      MockSetVolumeUseCase(),
      MockSetPlaybackSpeedUseCase(),
      MockSetRepeatModeUseCase(),
      MockSetShuffleModeUseCase(),
      MockSkipToQueueItemUseCase(),
      MockPlayFromQueueUseCase(),
      MockUpdateQueueUseCase(),
      MockAddQueueItemUseCase(),
      MockRemoveQueueItemUseCase(),
      MockMoveQueueItemUseCase(),
      MockLoadAudioPlayerDataUseCase(),
      mockSyncActivePlayback,
      MockCheckAudioPlayabilityUseCase(),
      mockSettingsCubit,
      mockAddOrUpdateHistory,
      MockAnalyticsService(),
      mockAppReviewTriggerManager,
    );
  }

  setUp(() {
    mockGetAudioStreams = MockGetAudioStreamsUseCase();
    mockSeekTo = MockSeekToUseCase();
    mockSyncActivePlayback = MockSyncActivePlaybackFromHandlerUseCase();
    when(mockSeekTo.call(any)).thenAnswer((_) async => const Right(null));
    mockSettingsCubit = MockSettingsCubit();
    mockAppReviewTriggerManager = MockAppReviewTriggerManager();
    mockAddOrUpdateHistory = MockAddOrUpdateHistoryUseCase();

    currentAudioSubject = BehaviorSubject<AudioEntity?>();
    playbackStateSubject = BehaviorSubject<PlaybackStateEntity>();
    queueSubject = BehaviorSubject<List<AudioEntity>>.seeded(<AudioEntity>[]);
    volumeSubject = BehaviorSubject<double>();
    speedSubject = BehaviorSubject<double>();
    positionSubject = BehaviorSubject<Duration>();

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
          id: 'h',
          surahId: 1,
          surahName: 's',
          surahNameEn: 's',
          reciterId: 'r',
          reciterName: 'r',
          moshafId: 1,
          moshafName: 'm',
          lastPositionMs: 0,
          durationMs: 0,
          audioUrl: 'u',
          playedAt: DateTime(2024),
        ),
      ),
    );

    when(mockGetAudioStreams.currentAudio).thenAnswer(
      (_) => currentAudioSubject,
    );
    when(mockGetAudioStreams.playbackState).thenAnswer(
      (_) => playbackStateSubject,
    );
    when(mockGetAudioStreams.queue).thenAnswer(
      (_) => queueSubject,
    );
    when(mockGetAudioStreams.volume).thenAnswer((_) => volumeSubject);
    when(mockGetAudioStreams.speed).thenAnswer((_) => speedSubject);
    when(mockGetAudioStreams.position).thenAnswer((_) => positionSubject);
    when(mockSettingsCubit.state).thenReturn(const SettingsState());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockSettingsCubit.isSleepTimerEnabledStream).thenAnswer(
      (_) => Stream<bool>.value(true),
    );
    when(mockAppReviewTriggerManager.onSessionStarted()).thenAnswer(
      (_) async {},
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

  final PlaybackStateEntity idlePlayback = PlaybackStateEntity(
    isPlaying: false,
    processingState: AudioProcessingStateStatus.idle,
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: Duration.zero,
    currentIndex: 0,
    queue: <AudioEntity>[],
  );

  group('syncActivePlayback after hot restart', () {
    test(
      'manual sync aligns bloc with handler surah and clears dismiss',
      () async {
        when(mockSyncActivePlayback.call()).thenAnswer(
          (_) async => Right(
            ActivePlaybackSnapshot(
              currentAudio: handlerSurah,
              playbackState: handlerPlayback,
            ),
          ),
        );
        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: hydratedSurah,
            dismissedAudioId: '1',
          ),
        );
        bloc.add(const AudioPlayerEvent.syncActivePlayback());
        await bloc.stream.firstWhere((s) => s.currentAudio?.id == '2');
        expect(bloc.state.dismissedAudioId, isNull);
        expect(bloc.state.shouldShowBottomPlayer, isTrue);
        await bloc.close();
      },
    );

    test('null snapshot sync demotes chrome but keeps currentAudio', () async {
      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => const Right(null),
      );
      final AudioPlayerBloc bloc = buildBloc();
      bloc.emit(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: hydratedSurah,
        ),
      );
      bloc.add(const AudioPlayerEvent.syncActivePlayback());
      await bloc.stream.firstWhere(
        (s) => s.status == AudioPlayerStatus.initial,
      );
      expect(bloc.state.currentAudio, hydratedSurah);
      expect(bloc.state.shouldShowBottomPlayer, isFalse);
      verify(mockSyncActivePlayback.call()).called(1);
      await bloc.close();
    });

    test('inactive handler snapshot dismisses mini player', () async {
      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => Right(
          ActivePlaybackSnapshot(
            currentAudio: hydratedSurah,
            playbackState: idlePlayback,
          ),
        ),
      );
      final AudioPlayerBloc bloc = buildBloc();
      bloc.emit(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: hydratedSurah,
        ),
      );
      bloc.add(const AudioPlayerEvent.syncActivePlayback());
      await bloc.stream.firstWhere((s) => !s.shouldShowBottomPlayer);
      expect(bloc.state.dismissedAudioId, hydratedSurah.id);
      expect(bloc.state.isSessionDismissed, isTrue);
      await bloc.close();
    });

    test('sync failure leaves state unchanged', () async {
      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => Left(ServerFailure('sync failed')),
      );
      final AudioPlayerBloc bloc = buildBloc();
      bloc.emit(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: hydratedSurah,
        ),
      );
      bloc.add(const AudioPlayerEvent.syncActivePlayback());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.currentAudio, hydratedSurah);
      await bloc.close();
    });

    test(
      'idle playback stream dismisses session when not already dismissed',
      () async {
        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: hydratedSurah,
          ),
        );
        playbackStateSubject.add(idlePlayback);
        await bloc.stream.firstWhere((s) => !s.shouldShowBottomPlayer);
        expect(bloc.state.dismissedAudioId, hydratedSurah.id);
        await bloc.close();
      },
    );

    test('already dismissed idle stream does not save history again', () async {
      final AudioPlayerBloc bloc = buildBloc();
      bloc.emit(
        AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: hydratedSurah,
          dismissedAudioId: hydratedSurah.id,
        ),
      );
      clearInteractions(mockAddOrUpdateHistory);
      playbackStateSubject.add(idlePlayback);
      await bloc.stream.firstWhere(
        (s) => s.playbackState?.processingState ==
            AudioProcessingStateStatus.idle,
      );
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
      await bloc.close();
    });

    test('scheduleActivePlaybackSyncOnCreate dispatches leading sync', () async {
      AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = true;
      addTearDown(() {
        AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = false;
      });

      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => const Right(null),
      );

      buildBloc();
      await Future<void>.delayed(Duration.zero);
      verify(mockSyncActivePlayback.call()).called(1);
    });

    test('active reconcile seeks handler to reported position', () async {
      const Duration reportedPosition = Duration(seconds: 90);
      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => Right(
          ActivePlaybackSnapshot(
            currentAudio: handlerSurah,
            playbackState: handlerPlayback.copyWith(
              position: reportedPosition,
            ),
          ),
        ),
      );
      final AudioPlayerBloc bloc = buildBloc();
      bloc.add(const AudioPlayerEvent.syncActivePlayback());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(mockSeekTo.call(reportedPosition)).called(1);
      await bloc.close();
    });

    test('syncActivePlaybackTrailing dispatches sync handler', () async {
      when(mockSyncActivePlayback.call()).thenAnswer(
        (_) async => const Right(null),
      );
      final AudioPlayerBloc bloc = buildBloc();
      bloc.add(const AudioPlayerEvent.syncActivePlaybackTrailing());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(mockSyncActivePlayback.call()).called(1);
      await bloc.close();
    });

  });

  group('hot restart mini player visibility', () {
    final PlaybackStateEntity pausedHandlerPlayback = PlaybackStateEntity(
      isPlaying: false,
      processingState: AudioProcessingStateStatus.ready,
      position: const Duration(seconds: 30),
      bufferedPosition: const Duration(minutes: 2),
      duration: const Duration(minutes: 1),
      currentIndex: 0,
      queue: <AudioEntity>[hydratedSurah],
      queueGeneration: 1,
    );

    ActivePlaybackSnapshot activeHandlerSnapshot() =>
        ActivePlaybackSnapshot(
          currentAudio: hydratedSurah,
          playbackState: pausedHandlerPlayback,
        );

    test(
      'documents pre-stream hydrated mismatch before handler events arrive',
      () {
        const AudioPlayerState hydratedAfterRestart = AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: hydratedSurah,
          dismissedAudioId: '1',
        );
        final ActivePlaybackSnapshot handlerSnapshot =
            activeHandlerSnapshot();

        expect(handlerSnapshot.currentAudio.id, hydratedSurah.id);
        expect(hydratedAfterRestart.shouldShowBottomPlayer, isFalse);
      },
    );

    test(
      'paused active handler stream restores mini player after hot restart',
      () async {
        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.initial,
            currentAudio: hydratedSurah,
            dismissedAudioId: '1',
          ),
        );

        currentAudioSubject.add(hydratedSurah);
        playbackStateSubject.add(pausedHandlerPlayback);

        await bloc.stream.firstWhere((s) => s.shouldShowBottomPlayer);

        expect(bloc.state.dismissedAudioId, isNull);
        expect(bloc.state.status, AudioPlayerStatus.success);
        expect(bloc.state.currentAudio, hydratedSurah);
        await bloc.close();
      },
    );

    test(
      'playing stream update clears dismiss and shows mini player without sync',
      () async {
        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: hydratedSurah,
            dismissedAudioId: '1',
          ),
        );

        playbackStateSubject.add(
          pausedHandlerPlayback.copyWith(isPlaying: true),
        );

        await bloc.stream.firstWhere((s) => s.shouldShowBottomPlayer);

        expect(bloc.state.dismissedAudioId, isNull);
        expect(bloc.state.currentAudio, hydratedSurah);
        await bloc.close();
      },
    );

    test(
      'leading reconcile on create restores mini player for active handler snapshot',
      () async {
        AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = true;
        addTearDown(() {
          AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = false;
        });

        when(mockSyncActivePlayback.call()).thenAnswer(
          (_) async => Right(activeHandlerSnapshot()),
        );

        final AudioPlayerBloc bloc = buildBloc();
        await bloc.stream.firstWhere((s) => s.shouldShowBottomPlayer);

        expect(bloc.state.currentAudio, hydratedSurah);
        expect(bloc.state.dismissedAudioId, isNull);
        await bloc.close();
      },
    );

    test(
      'trailing reconcile after null leading restores mini player on startup burst',
      () async {
        var syncCalls = 0;
        when(mockSyncActivePlayback.call()).thenAnswer((_) async {
          syncCalls++;
          if (syncCalls == 1) {
            return const Right(null);
          }
          return Right(activeHandlerSnapshot());
        });

        AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = true;
        addTearDown(() {
          AudioPlayerBloc.scheduleActivePlaybackSyncOnCreate = false;
        });

        final AudioPlayerBloc bloc = buildBloc();
        expect(bloc.state.shouldShowBottomPlayer, isFalse);

        bloc.add(const AudioPlayerEvent.requestPlaybackReconciliation());
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(syncCalls, greaterThanOrEqualTo(2));
        expect(bloc.state.shouldShowBottomPlayer, isTrue);
        expect(bloc.state.dismissedAudioId, isNull);
        await bloc.close();
      },
    );

    test(
      'requestPlaybackReconciliation restores mini player when streams stay silent',
      () async {
        when(mockSyncActivePlayback.call()).thenAnswer(
          (_) async => Right(activeHandlerSnapshot()),
        );

        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: hydratedSurah,
            dismissedAudioId: '1',
          ),
        );
        expect(bloc.state.shouldShowBottomPlayer, isFalse);

        bloc.add(const AudioPlayerEvent.requestPlaybackReconciliation());
        await bloc.stream.firstWhere((s) => s.shouldShowBottomPlayer);

        expect(bloc.state.dismissedAudioId, isNull);
        verify(mockSyncActivePlayback.call()).called(greaterThanOrEqualTo(1));
        await bloc.close();
      },
    );
  });

  group('isSessionDismissed presentation status', () {
    test(
      'isSessionDismissed is true when dismiss id matches current audio',
      () {
        const AudioPlayerState state = AudioPlayerState(
          status: AudioPlayerStatus.initial,
          currentAudio: hydratedSurah,
          dismissedAudioId: '1',
        );
        expect(state.isSessionDismissed, isTrue);
        expect(state.shouldShowBottomPlayer, isFalse);
      },
    );

    test(
      'position updates keep initial status when session dismissed',
      () async {
        final AudioPlayerBloc bloc = buildBloc();
        bloc.emit(
          const AudioPlayerState(
            status: AudioPlayerStatus.initial,
            currentAudio: hydratedSurah,
            dismissedAudioId: '1',
          ),
        );
        bloc.add(
          const AudioPlayerEvent.updatePositionData(
            PositionData(
              position: Duration(seconds: 5),
              bufferedPosition: Duration(seconds: 10),
              duration: Duration(minutes: 1),
            ),
          ),
        );
        await bloc.stream.firstWhere(
          (s) => s.positionData?.position == const Duration(seconds: 5),
        );
        expect(bloc.state.status, AudioPlayerStatus.initial);
        expect(bloc.state.isSessionDismissed, isTrue);
        await bloc.close();
      },
    );
  });
}
