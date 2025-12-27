import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';
import 'package:tilawa/shared/widgets/expanded_player_screen.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

class MockAudioPositionService extends Mock implements AudioPositionService {}

void main() {
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockAudioPositionService mockAudioPositionService;

  Future<void> setScreenSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUpAll(() {
    registerFallbackValue(const AudioPlayerEvent.playAudio());
  });

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.allowReassignment = true;

    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockAudioPositionService = MockAudioPositionService();

    // Register mocks
    GetIt.instance.registerSingleton<AudioPositionService>(
      mockAudioPositionService,
    );
    GetIt.instance.registerSingleton<DownloadsRepository>(
      MockDownloadsRepository(),
    );
    GetIt.instance.registerSingleton<AudioPlayerHandler>(
      MockAudioPlayerHandler(),
    );

    // Default Stubs
    when(
      () => mockAudioPositionService.position,
    ).thenAnswer((_) => Stream.value(Duration.zero));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<AudioPlayerBloc>.value(
      value: mockAudioPlayerBloc,
      child: const ScreenUtilPlusInit(
        designSize: Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          locale: Locale('en'),
          home: ExpandedPlayerScreen(),
        ),
      ),
    );
  }

  testWidgets('ExpandedPlayerScreen displays content when playing', (
    tester,
  ) async {
    await setScreenSize(tester);

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
          position: Duration(minutes: 1),
          bufferedPosition: Duration(minutes: 2),
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        ),
        positionData: PositionData(
          position: Duration(minutes: 1),
          bufferedPosition: Duration(minutes: 2),
          duration: Duration(minutes: 5),
        ),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Title and Artist
    expect(find.text('Test Surah'), findsOneWidget);
    expect(find.text('Test Reciter'), findsOneWidget);

    // Verify Time
    // 01:00 / 05:00
    // Note: The new UI logic for formatting might differ slightly
    // but the test expects 01:00 and 05:00.
    // User's code: _formatDuration logic is standard HH:MM:SS or MM:SS
    // 1m = 01:00, 5m = 05:00. Should match.
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    // Verify Play/Pause (Playing -> Pause icon)
    // Updated to filled icons as per new implementation
    expect(find.byIcon(FluentIcons.pause_24_filled), findsOneWidget);
    expect(find.byIcon(FluentIcons.play_24_filled), findsNothing);
  });

  testWidgets('Play button triggers event when pressed', (tester) async {
    await setScreenSize(tester);

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
        positionData: PositionData(
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 5),
        ),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Play icon
    expect(find.byIcon(FluentIcons.play_24_filled), findsOneWidget);

    // Tap Play
    await tester.tap(find.byIcon(FluentIcons.play_24_filled));
    verify(
      () => mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
    ).called(1);
  });
}
