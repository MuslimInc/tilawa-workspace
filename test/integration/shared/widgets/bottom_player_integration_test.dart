import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/widgets/bottom_player_widget.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

void main() {
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockSettingsCubit mockSettingsCubit;
  late MockAudioPlayerHandler mockAudioPlayerHandler;

  setUp(() {
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockSettingsCubit = MockSettingsCubit();
    mockAudioPlayerHandler = MockAudioPlayerHandler();

    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());

    GetIt.instance.registerSingleton<AudioPlayerHandler>(
      mockAudioPlayerHandler,
    );
    when(
      () => mockAudioPlayerHandler.getRecitersData(
        languageCode: any(named: 'languageCode'),
      ),
    ).thenAnswer((_) async => null);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
        BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
      ],
      child: const ScreenUtilPlusInit(
        designSize: Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomPlayerWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('BottomPlayer Integration Tests', () {
    testWidgets('should rely on hasMediaItem to determine visibility', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockAudioPlayerBloc.state,
      ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert: Should be effectively invisible (SizedBox.shrink)
      expect(find.byType(Container), findsNothing);
      expect(find.text('Unknown Reciter'), findsNothing);
    });

    testWidgets(
      'should display media info when currentAudio is present and status is success',
      (tester) async {
        // Arrange
        const testAudio = AudioEntity(
          id: '1',
          title: 'Surah Al-Fatiha',
          artist: 'Mishary Rashid',
          url: 'url',
          duration: Duration(minutes: 5),
        );

        when(() => mockAudioPlayerBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: testAudio,
            playbackState: PlaybackStateEntity(
              isPlaying: true,
              processingState: AudioProcessingStateStatus.ready,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
              currentIndex: 0,
              queue: [],
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Surah Al-Fatiha'), findsOneWidget);
        expect(find.text('Mishary Rashid'), findsOneWidget);
        expect(find.byIcon(FluentIcons.pause_16_filled), findsOneWidget);
      },
    );

    testWidgets('should toggle play/pause icon based on isPlaying state', (
      tester,
    ) async {
      // Arrange: Paused state
      const testAudio = AudioEntity(
        id: '1',
        title: 'Surah Al-Fatiha',
        artist: 'Mishary Rashid',
        url: 'url',
        duration: Duration(minutes: 5),
      );

      when(() => mockAudioPlayerBloc.state).thenReturn(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: testAudio,
          playbackState: PlaybackStateEntity(
            isPlaying: false,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
            currentIndex: 0,
            queue: [],
          ), // Paused
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert: Play icon should be visible
      expect(find.byIcon(FluentIcons.play_16_filled), findsOneWidget);
      expect(find.byIcon(FluentIcons.pause_16_filled), findsNothing);
    });

    testWidgets('should add PlayAudio event when play button is tapped', (
      tester,
    ) async {
      // Arrange
      const testAudio = AudioEntity(
        id: '1',
        title: 'Surah Al-Fatiha',
        artist: 'Mishary Rashid',
        url: 'url',
        duration: Duration(minutes: 5),
      );

      when(() => mockAudioPlayerBloc.state).thenReturn(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: testAudio,
          playbackState: PlaybackStateEntity(
            isPlaying: false,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
            currentIndex: 0,
            queue: [],
          ), // Paused
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find play button and tap
      final Finder playButtonFinder = find.byIcon(FluentIcons.play_16_filled);
      await tester.tap(playButtonFinder);
      await tester.pump();

      // Assert
      verify(
        () => mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
      ).called(1);
    });

    testWidgets('should add PauseAudio event when pause button is tapped', (
      tester,
    ) async {
      // Arrange
      const testAudio = AudioEntity(
        id: '1',
        title: 'Surah Al-Fatiha',
        artist: 'Mishary Rashid',
        url: 'url',
        duration: Duration(minutes: 5),
      );

      when(() => mockAudioPlayerBloc.state).thenReturn(
        const AudioPlayerState(
          status: AudioPlayerStatus.success,
          currentAudio: testAudio,
          playbackState: PlaybackStateEntity(
            isPlaying: true,
            processingState: AudioProcessingStateStatus.ready,
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            duration: Duration.zero,
            currentIndex: 0,
            queue: [],
          ), // Playing
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find pause button and tap
      final Finder pauseButtonFinder = find.byIcon(FluentIcons.pause_16_filled);
      await tester.tap(pauseButtonFinder);
      await tester.pump();

      // Assert
      verify(
        () => mockAudioPlayerBloc.add(const AudioPlayerEvent.pauseAudio()),
      ).called(1);
    });
  });
}
