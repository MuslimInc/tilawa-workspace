import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/position_data.dart';
import 'package:muzakri/shared/services/audio_position_service.dart';
import 'package:muzakri/shared/widgets/expanded_player_screen.dart';

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
      child: ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: ExpandedPlayerScreen(
            audioPositionService: mockAudioPositionService,
          ),
        ),
      ),
    );
  }

  testWidgets('ExpandedPlayerScreen displays content when playing', (
    tester,
  ) async {
    await setScreenSize(tester);

    // Override stub
    when(
      () => mockAudioPositionService.position,
    ).thenAnswer((_) => Stream.value(const Duration(minutes: 1)));

    const testMediaItem = MediaItem(
      id: '1',
      title: 'Test Surah',
      artist: 'Test Reciter',
      duration: Duration(minutes: 5),
    );

    when(() => mockAudioPlayerBloc.state).thenReturn(
      AudioPlayerState(
        status: AudioPlayerStatus.success,
        mediaItem: testMediaItem,
        playbackState: PlaybackState(playing: true),
        positionData: const PositionData(
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
    // 00:01:00 / 00:05:00
    expect(find.text('00:01:00'), findsOneWidget);
    expect(find.text('00:05:00'), findsOneWidget);

    // Verify Play/Pause (Playing -> Pause icon)
    expect(find.byIcon(FluentIcons.pause_24_regular), findsOneWidget);
    expect(find.byIcon(FluentIcons.play_24_regular), findsNothing);
  });

  testWidgets('Play button triggers event when pressed', (tester) async {
    await setScreenSize(tester);

    const testMediaItem = MediaItem(
      id: '1',
      title: 'Test Surah',
      artist: 'Test Reciter',
    );

    when(() => mockAudioPlayerBloc.state).thenReturn(
      AudioPlayerState(
        status: AudioPlayerStatus.success,
        mediaItem: testMediaItem,
        playbackState: PlaybackState(), // Paused
        positionData: const PositionData(
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 5),
        ),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Play icon
    expect(find.byIcon(FluentIcons.play_24_regular), findsOneWidget);

    // Tap Play
    await tester.tap(find.byIcon(FluentIcons.play_24_regular));
    verify(
      () => mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
    ).called(1);
  });
}
