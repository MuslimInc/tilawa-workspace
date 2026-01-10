import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/word_by_word_audio_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_text_section.dart';

class MockWordByWordAudioBloc
    extends MockBloc<WordByWordAudioEvent, WordByWordAudioState>
    implements WordByWordAudioBloc {}

class FakeWordByWordAudioEvent extends Fake implements WordByWordAudioEvent {}

class FakeWordByWordAudioState extends Fake implements WordByWordAudioState {}

void main() {
  late MockWordByWordAudioBloc mockWordByWordAudioBloc;

  setUpAll(() {
    registerFallbackValue(FakeWordByWordAudioEvent());
    registerFallbackValue(FakeWordByWordAudioState());
  });

  setUp(() {
    mockWordByWordAudioBloc = MockWordByWordAudioBloc();
    when(
      () => mockWordByWordAudioBloc.state,
    ).thenReturn(const WordByWordAudioState());
    when(
      () => mockWordByWordAudioBloc.stream,
    ).thenAnswer((_) => Stream.value(const WordByWordAudioState()));
  });

  Widget createWidgetUnderTest({
    required List<QuranWord> words,
    double fontSize = 24.0,
    int surahNumber = 1,
    int ayahNumber = 1,
  }) {
    return MaterialApp(
      home: BlocProvider<WordByWordAudioBloc>.value(
        value: mockWordByWordAudioBloc,
        child: Scaffold(
          body: SurahTextSection(
            fontSize: fontSize,
            words: words,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          ),
        ),
      ),
    );
  }

  group('SurahTextSection', () {
    testWidgets('renders RichText with correct font and size', (
      WidgetTester tester,
    ) async {
      // Arrange
      const fontSize = 30.0;
      const fontFamily = 'Noto Nastaliq Urdu';

      const word1 = QuranWord(
        id: 1,
        position: 1,
        text: 'Word1',
        charTypeName: 'word',
        codeV1: 'Code1',
        fontFamily: fontFamily,
        renderedText: 'Word1',
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [word1],
      );

      // Act
      await tester.pumpWidget(
        createWidgetUnderTest(fontSize: fontSize, words: [word1]),
      );

      // Assert
      final Finder richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);

      final RichText richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;

      // Non-QCF font uses textUthmani or text
      expect(wordSpan.text, 'Word1');
      expect(wordSpan.style!.fontSize, fontSize);
      expect(wordSpan.style!.fontFamily, fontFamily);
      expect(wordSpan.style!.color, Colors.black);
    });

    testWidgets('highlights word when playing', (WidgetTester tester) async {
      // Arrange
      const playingWordId = 10;
      when(
        () => mockWordByWordAudioBloc.state,
      ).thenReturn(const WordByWordAudioState(playingWordId: playingWordId));

      const word1 = QuranWord(
        id: playingWordId,
        position: 1,
        text: 'Word1',
        charTypeName: 'word',
        codeV1: 'Code1',
        fontFamily: 'QCF_P001',
        renderedText: 'Word1',
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [word1],
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(words: [word1]));

      // Assert
      final Finder richTextFinder = find.byType(RichText);
      final RichText richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;

      expect(wordSpan.style!.color, Colors.amber[900]);
      expect(wordSpan.style!.backgroundColor, isNotNull);
    });

    testWidgets('dispatches playWord event when word is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      const wordId = 5;
      const word1 = QuranWord(
        id: wordId,
        position: 1,
        text: 'Word1',
        charTypeName: 'word',
        codeV1: 'Code1',
        fontFamily: 'QCF_P001',
        renderedText: 'Word1',
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [word1],
      );

      await tester.pumpWidget(createWidgetUnderTest(words: [word1]));

      // Act
      await tester.tap(find.byType(RichText));

      // Assert
      verify(
        () =>
            mockWordByWordAudioBloc.add(any(that: isA<WordByWordAudioEvent>())),
      ).called(1);
    });

    testWidgets('renders ayah end marker correctly', (
      WidgetTester tester,
    ) async {
      // Arrange - end word with pre-computed rendering values
      const endWord = QuranWord(
        id: 99,
        position: 2,
        text: '',
        charTypeName: 'end',
        codeV1: 'EndMarker',
        // Pre-computed by data layer
        renderedText: 'EndMarker',
        fontFamily: 'QCF_P001',
        lineHeight: 1.6,
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [endWord],
      );

      // Act - Use QCF font
      await tester.pumpWidget(createWidgetUnderTest(words: [endWord]));

      // Assert - uses pre-computed renderedText
      final Finder richTextFinder = find.byType(RichText);
      final RichText richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;
      final endTagSpan = textSpan.children![0] as TextSpan;

      expect(endTagSpan.text, 'EndMarker');
      expect(endTagSpan.style!.color, const Color(0xFFD4AF37));
    });

    testWidgets('renders pre-computed renderedText when available', (
      WidgetTester tester,
    ) async {
      // Arrange - data layer pre-computes rendering values
      const word = QuranWord(
        id: 1,
        position: 1,
        text: 'Plain',
        textUthmani: 'Uthmani',
        codeV1: 'CodeV1',
        charTypeName: 'word',
        // Pre-computed by data layer
        renderedText: 'CodeV1',
        fontFamily: 'QCF_P001',
        lineHeight: 1.6,
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah',
        surahName: 'Surah',
        surahNameEnglish: 'English',
        words: [word],
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(words: [word]));

      // Assert - uses pre-computed values
      final RichText richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;
      expect(wordSpan.text, 'CodeV1');
      expect(wordSpan.style!.fontFamily, 'QCF_P001');
    });

    testWidgets('uses pre-computed font values from data layer', (
      WidgetTester tester,
    ) async {
      // Arrange - data layer pre-computes for non-QCF case
      const word = QuranWord(
        id: 1,
        position: 1,
        text: 'Plain',
        textUthmani: 'Uthmani',
        codeV1: 'CodeV1',
        charTypeName: 'word',
        // Pre-computed by data layer for non-QCF
        renderedText: 'Uthmani',
        fontFamily: 'Noto Nastaliq Urdu',
        lineHeight: 2.2,
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah',
        surahName: 'Surah',
        surahNameEnglish: 'English',
        words: [word],
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(words: [word]));

      // Assert - uses pre-computed values
      final RichText richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;
      expect(wordSpan.text, 'Uthmani');
      expect(wordSpan.style!.fontFamily, 'Noto Nastaliq Urdu');
    });

    testWidgets('renders plain text when no renderedText or textUthmani', (
      WidgetTester tester,
    ) async {
      // Arrange - word with only plain text
      const word = QuranWord(
        id: 1,
        position: 1,
        text: 'Plain',
        charTypeName: 'word',
        renderedText: 'Plain',
        // No pre-computed values
      );
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah',
        surahName: 'Surah',
        surahNameEnglish: 'English',
        words: [word],
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(words: [word]));

      // Assert - falls back to word.text
      final RichText richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;
      expect(wordSpan.text, 'Plain');
    });

    testWidgets('renders plain text fallback when ayahs words are null', (
      WidgetTester tester,
    ) async {
      // Arrange
      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Fallback Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(words: []));

      // Assert
      final Finder richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);

      final RichText richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;

      // One span for fallback text, one for end symbol
      expect(textSpan.children!.length, 2);

      final contentSpan = textSpan.children![0] as TextSpan;
      expect(contentSpan.text, 'Fallback Text');
    });
  });
}
