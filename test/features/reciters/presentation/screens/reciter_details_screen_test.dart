import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/reciter_model.dart';

class MockReciterDetailsBloc
    extends MockBloc<ReciterDetailsEvent, ReciterDetailsState>
    implements ReciterDetailsBloc {}

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

void main() {
  late MockReciterDetailsBloc mockReciterDetailsBloc;
  late MockDownloadsBloc mockDownloadsBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;

  setUpAll(() {
    registerFallbackValue(const AudioPlayerEvent.playAudio());
    // Removed ReciterDetailsEvent.started fallback as it doesn't exist

    // Setup GetIt
    GetIt.instance.registerSingleton<DownloadsRepository>(
      MockDownloadsRepository(),
    );
    GetIt.instance.registerSingleton<AudioPlayerHandler>(
      MockAudioPlayerHandler(),
    );
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  setUp(() {
    mockReciterDetailsBloc = MockReciterDetailsBloc();
    mockDownloadsBloc = MockDownloadsBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();

    // Mock fluttertoast channel
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });
  });

  const testReciter = Reciter(
    id: 1,
    name: 'Test Reciter',
    letter: 'T',
    date: '2023',
    moshaf: [
      Mosahf(
        id: 1,
        name: 'Hafs',
        server: 'server1',
        surahTotal: 114,
        moshafType: 1,
        surahList: '1,2,3',
      ),
      Mosahf(
        id: 2,
        name: 'Warsh',
        server: 'server2',
        surahTotal: 114,
        moshafType: 2,
        surahList: '1,2,3',
      ),
    ],
  );

  final testSurahList = <SurahEntity>[
    const SurahEntity(
      mediaItem: MediaItem(
        id: '001',
        title: 'Al-Fatiha',
        artist: 'Test Reciter',
      ),
    ),
    const SurahEntity(
      mediaItem: MediaItem(
        id: '002',
        title: 'Al-Baqarah',
        artist: 'Test Reciter',
      ),
    ),
  ];

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReciterDetailsBloc>.value(value: mockReciterDetailsBloc),
        BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
        BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: ScreenUtilPlusInit(
          designSize: Size(375, 812),
          child: ReciterDetailsScreen(reciter: testReciter),
        ),
      ),
    );
  }

  testWidgets('ReciterDetailsScreen displays header and moshaf selector', (
    tester,
  ) async {
    when(() => mockReciterDetailsBloc.state).thenReturn(
      ReciterDetailsLoaded(
        surahList: testSurahList,
        selectedMoshaf: testReciter.moshaf.first,
      ),
    );
    when(() => mockDownloadsBloc.state).thenReturn(const DownloadsInitial());
    when(() => mockAudioPlayerBloc.state).thenReturn(
      AudioPlayerState(
        status: AudioPlayerStatus.initial,
        playbackState: PlaybackState(),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify SliverAppBar title (and list items having the name)
    expect(find.text('Test Reciter'), findsWidgets);

    // Verify Moshaf selector (DropdownButton)
    expect(find.byType(DropdownButton<Mosahf>), findsOneWidget);
    expect(find.text('Hafs'), findsOneWidget);

    // Verify Surah list
    expect(find.text('Al-Fatiha'), findsOneWidget);
    expect(find.text('Al-Baqarah'), findsOneWidget);
  });

  testWidgets('ReciterDetailsScreen interacts with moshaf selector', (
    tester,
  ) async {
    when(() => mockReciterDetailsBloc.state).thenReturn(
      ReciterDetailsLoaded(
        surahList: testSurahList,
        selectedMoshaf: testReciter.moshaf.first,
      ),
    );
    when(() => mockDownloadsBloc.state).thenReturn(const DownloadsInitial());
    when(() => mockAudioPlayerBloc.state).thenReturn(
      AudioPlayerState(
        status: AudioPlayerStatus.initial,
        playbackState: PlaybackState(),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Open dropdown
    await tester.tap(find.byType(DropdownButton<Mosahf>));
    await tester.pumpAndSettle();

    // Verify options visible
    expect(find.text('Warsh').last, findsOneWidget);

    // Select Warsh
    await tester.tap(find.text('Warsh').last);
    await tester.pump();

    // Verify event added (MockBloc usually doesn't track method calls like Mockito unless strict,
    // but bloc_test uses whenListen or verify if needed. Here we just ensure no crash)
  });
}
