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
import 'package:muzakri/shared/widgets/expanded_player_screen.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

void main() {
  late MockAudioPlayerBloc mockAudioPlayerBloc;

  setUpAll(() {
    registerFallbackValue(const AudioPlayerEvent.playAudio());

    if (!GetIt.instance.isRegistered<DownloadsRepository>()) {
      GetIt.instance.registerSingleton<DownloadsRepository>(
        MockDownloadsRepository(),
      );
    }
    if (!GetIt.instance.isRegistered<AudioPlayerHandler>()) {
      GetIt.instance.registerSingleton<AudioPlayerHandler>(
        MockAudioPlayerHandler(),
      );
    }
  });

  setUp(() {
    mockAudioPlayerBloc = MockAudioPlayerBloc();
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
    const testMediaItem = MediaItem(
      id: '1',
      title: 'Test Surah',
      artist: 'Test Reciter',
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
    // 01:00 / 05:00
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    // Verify Play/Pause (Playing -> Pause icon)
    expect(find.byIcon(FluentIcons.pause_24_filled), findsOneWidget);
    expect(find.byIcon(FluentIcons.play_24_filled), findsNothing);
  });

  testWidgets('Play button triggers event when pressed', (tester) async {
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
    expect(find.byIcon(FluentIcons.play_24_filled), findsOneWidget);

    // Tap Play
    await tester.tap(find.byIcon(FluentIcons.play_24_filled));
    verify(
      () => mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
    ).called(1);
  });
}
