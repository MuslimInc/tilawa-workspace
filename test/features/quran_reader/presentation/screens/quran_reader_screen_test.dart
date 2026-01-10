import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/word_by_word_audio_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_reader_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/widgets.dart';
import 'package:tilawa/l10n/l10n.dart';

class MockQuranReaderBloc extends MockBloc<QuranReaderEvent, QuranReaderState>
    implements QuranReaderBloc {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

class MockWordByWordAudioBloc
    extends MockBloc<WordByWordAudioEvent, WordByWordAudioState>
    implements WordByWordAudioBloc {}

void main() {
  late MockQuranReaderBloc mockQuranReaderBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockWordByWordAudioBloc mockWordByWordAudioBloc;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    mockQuranReaderBloc = MockQuranReaderBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockWordByWordAudioBloc = MockWordByWordAudioBloc();

    when(
      () => mockWordByWordAudioBloc.state,
    ).thenReturn(const WordByWordAudioState());

    if (getIt.isRegistered<AudioPlayerBloc>()) {
      getIt.unregister<AudioPlayerBloc>();
    }
    getIt.registerSingleton<AudioPlayerBloc>(mockAudioPlayerBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<QuranReaderBloc>.value(value: mockQuranReaderBloc),
          BlocProvider<WordByWordAudioBloc>.value(
            value: mockWordByWordAudioBloc,
          ),
        ],
        child: const QuranReaderScreen(surahNumber: 1),
      ),
    );
  }

  testWidgets('QuranReaderScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Arrange
    const dummyAyah = PageAyahInfo(
      surahNumber: 1,
      ayahNumber: 1,
      text: 'Basmalah',
      surahName: 'Al-Fatiha',
      surahNameEnglish: 'The Opening',
    );

    const page1 = QuranPageEntity(
      pageNumber: 1,
      ayahs: [dummyAyah],
      juz: 1,
      hizb: 1,
    );

    const initialState = QuranReaderState(
      status: QuranReaderStatus.loaded,
      pages: {1: page1},
      currentPage: page1,
    );
    when(() => mockQuranReaderBloc.state).thenReturn(initialState);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Allow animations to settle

    // Assert
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(QuranReaderAppBar), findsOneWidget);
    expect(find.byType(QuranReaderBottomBar), findsOneWidget);
  });
}
