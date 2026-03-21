import 'package:tilawa/test_support/screenutil_compat.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/bottom_player_widget.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

void main() {
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockSettingsCubit mockSettingsCubit;

  setUpAll(() {
    registerFallbackValue(const AudioPlayerEvent.playAudio());

    // Setup GetIt
    if (!GetIt.instance.isRegistered<DownloadsRepository>()) {
      GetIt.instance.registerSingleton<DownloadsRepository>(
        MockDownloadsRepository(),
      );
    }
    if (!GetIt.instance.isRegistered<AudioPlayerHandler>()) {
      final mockHandler = MockAudioPlayerHandler();
      // Stub getRecitersData to return a Future to avoid null errors
      when(
        () => mockHandler.getRecitersData(
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async => null);
      GetIt.instance.registerSingleton<AudioPlayerHandler>(mockHandler);
    }
  });

  setUp(() {
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockSettingsCubit = MockSettingsCubit();
    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
        BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
      ],
      child: const ScreenUtilPlusInit(
        designSize: Size(375, 812),
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Content')),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomPlayerWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('BottomPlayer is hidden when status is not success', (
    tester,
  ) async {
    when(
      () => mockAudioPlayerBloc.state,
    ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(BottomPlayerWidget), findsOneWidget);
    // Should be invisible (SizedBox.shrink) - finding by key or specific child is hard if it returned SizedBox.shrink.
    // We can check that no text or icons from the player are visible.
    expect(find.byIcon(FluentIcons.play_24_filled), findsNothing);
  });

  testWidgets('BottomPlayer displays info and controls when playing', (
    tester,
  ) async {
    const testAudio = AudioEntity(
      id: '1',
      title: 'Test Surah',
      url: '1',
      artist: 'Test Reciter',
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
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        ),
        positionData: PositionData(
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 5),
        ),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify Title and Artist
    expect(find.text('Test Surah'), findsOneWidget);
    expect(find.text('Test Reciter'), findsOneWidget);

    // Verify Pause icon is shown (since playing: true)
    expect(find.byIcon(FluentIcons.pause_16_filled), findsOneWidget);
    expect(find.byIcon(FluentIcons.play_16_filled), findsNothing);
  });

  testWidgets('BottomPlayer displays play icon when paused', (tester) async {
    const testAudio = AudioEntity(
      id: '1',
      title: 'Test Surah',
      url: '1',
      artist: 'Test Reciter',
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
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        ), // Paused
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify Play icon is shown
    expect(find.byIcon(FluentIcons.play_16_filled), findsOneWidget);
  });
}
