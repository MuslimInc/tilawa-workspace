import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/settings/quran_settings_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/word_by_word_audio_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_page_widget.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_text_section.dart';

class MockQuranReaderBloc extends MockBloc<QuranReaderEvent, QuranReaderState>
    implements QuranReaderBloc {}

class MockQuranSettingsBloc
    extends MockBloc<QuranSettingsEvent, QuranSettingsState>
    implements QuranSettingsBloc {}

class MockWordByWordAudioBloc
    extends MockBloc<WordByWordAudioEvent, WordByWordAudioState>
    implements WordByWordAudioBloc {}

void main() {
  late MockQuranReaderBloc mockQuranReaderBloc;
  late MockQuranSettingsBloc mockQuranSettingsBloc;
  late MockWordByWordAudioBloc mockWordByWordAudioBloc;

  setUp(() {
    mockQuranReaderBloc = MockQuranReaderBloc();
    mockQuranSettingsBloc = MockQuranSettingsBloc();
    mockWordByWordAudioBloc = MockWordByWordAudioBloc();

    when(() => mockQuranReaderBloc.state).thenReturn(const QuranReaderState());
    when(
      () => mockQuranReaderBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockQuranSettingsBloc.state,
    ).thenReturn(const QuranSettingsState());
    when(
      () => mockQuranSettingsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockWordByWordAudioBloc.state,
    ).thenReturn(const WordByWordAudioState());
    when(
      () => mockWordByWordAudioBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest(QuranPageEntity page, {double fontSize = 28.0}) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<QuranReaderBloc>.value(value: mockQuranReaderBloc),
          BlocProvider<QuranSettingsBloc>.value(value: mockQuranSettingsBloc),
          BlocProvider<WordByWordAudioBloc>.value(
            value: mockWordByWordAudioBloc,
          ),
        ],
        child: Scaffold(
          body: QuranPageWidget(page: page, fontSize: fontSize),
        ),
      ),
    );
  }

  testWidgets(
    'renders RichText with correct styles in initial state (no highlighting)',
    (WidgetTester tester) async {
      // Arrange
      const fontSize = 28.0;
      when(() => mockQuranSettingsBloc.state).thenReturn(
        const QuranSettingsState(
          settings: ReaderSettingsEntity(fontSize: fontSize),
        ),
      );

      const word1 = QuranWord(
        id: 1,
        position: 1,
        text: 'Word1',
        charTypeName: 'word',
        codeV1: 'Code1',
        // Pre-computed by data layer
        renderedText: 'Code1',
        fontFamily: 'QCF_P001',
        lineHeight: 1.6,
      );
      const word2 = QuranWord(
        id: 2,
        position: 2,
        text: 'Word2',
        charTypeName: 'word',
        codeV1: 'Code2',
        // Pre-computed by data layer
        renderedText: 'Code2',
        fontFamily: 'QCF_P001',
        lineHeight: 1.6,
      );

      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [word1, word2],
      );

      const page = QuranPageEntity(
        pageNumber: 1,
        ayahs: [ayah],
        juz: 1,
        hizb: 1,
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(page));

      // Assert
      final Finder surahTextSectionFinder = find.byType(SurahTextSection);
      expect(surahTextSectionFinder, findsOneWidget);

      final Finder richTextFinder = find.descendant(
        of: surahTextSectionFinder,
        matching: find.byType(RichText),
      );
      expect(richTextFinder, findsOneWidget);

      final RichText richText = tester.widget<RichText>(richTextFinder);
      expect(richText.textAlign, TextAlign.center);
      expect(richText.textDirection, TextDirection.rtl);

      final textSpan = richText.text as TextSpan;
      final List<InlineSpan> children = textSpan.children!;

      // We expect 2 words + maybe ayah end marker or fallbacks.
      // Based on SurahTextSection logic:
      // Loop over words. If not 'end', add TextSpan.
      // Then add Ayah End symbol.

      // Let's verify the word spans
      // Word 1
      final span1 = children[0] as TextSpan;
      expect(span1.text, 'Code1'); // QCF font usage for Uthmani
      expect(span1.style!.fontSize, fontSize);
      expect(span1.style!.color, Colors.black);
      expect(span1.style!.backgroundColor, null);

      // Word 2
      final span2 = children[1] as TextSpan;
      expect(span2.text, 'Code2');
      expect(span2.style!.fontSize, fontSize);
      expect(span2.style!.color, Colors.black);
      expect(span2.style!.backgroundColor, null);

      // Verify no highlighting effects are present
      for (final child in children) {
        if (child is TextSpan && child.style != null) {
          // Check if it's one of our words (not the ayah end marker which might be gold)
          if (child.text == 'Code1' || child.text == 'Code2') {
            expect(
              child.style!.color,
              Colors.black,
              reason: 'Word should be black when not playing',
            );
            expect(
              child.style!.backgroundColor,
              null,
              reason: 'Background should be null when not playing',
            );
          }
        }
      }
    },
  );

  testWidgets('renders with custom font size when provided', (
    WidgetTester tester,
  ) async {
    // Arrange - now widget receives font size directly
    const customFontSize = 35.0;

    const word1 = QuranWord(
      id: 1,
      position: 1,
      text: 'Word1',
      charTypeName: 'word',
      codeV1: 'Code1',
    );

    const ayah = PageAyahInfo(
      surahNumber: 1,
      ayahNumber: 1,
      text: 'Ayah Text',
      surahName: 'Surah Name',
      surahNameEnglish: 'Surah Name English',
      words: [word1],
    );

    const page = QuranPageEntity(pageNumber: 1, ayahs: [ayah], juz: 1, hizb: 1);

    // Act - pass custom font size directly
    await tester.pumpWidget(
      createWidgetUnderTest(page, fontSize: customFontSize),
    );

    // Assert - widget renders with the provided font size
    final Finder surahTextSectionFinder = find.byType(SurahTextSection);
    final Finder richTextFinder = find.descendant(
      of: surahTextSectionFinder,
      matching: find.byType(RichText),
    );

    final RichText richText = tester.widget<RichText>(richTextFinder);
    final textSpan = richText.text as TextSpan;
    final wordSpan = textSpan.children![0] as TextSpan;

    expect(wordSpan.style!.fontSize, customFontSize);
  });

  testWidgets(
    'renders with default font size (28.0) from createWidgetUnderTest',
    (WidgetTester tester) async {
      // Arrange
      const word1 = QuranWord(
        id: 1,
        position: 1,
        text: 'Word1',
        charTypeName: 'word',
        codeV1: 'Code1',
      );

      const ayah = PageAyahInfo(
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Ayah Text',
        surahName: 'Surah Name',
        surahNameEnglish: 'Surah Name English',
        words: [word1],
      );

      const page = QuranPageEntity(
        pageNumber: 1,
        ayahs: [ayah],
        juz: 1,
        hizb: 1,
      );

      // Act - use default font size from createWidgetUnderTest
      await tester.pumpWidget(createWidgetUnderTest(page));

      // Assert - widget renders with default font size (28.0)
      final Finder surahTextSectionFinder = find.byType(SurahTextSection);
      final Finder richTextFinder = find.descendant(
        of: surahTextSectionFinder,
        matching: find.byType(RichText),
      );

      final RichText richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;
      final wordSpan = textSpan.children![0] as TextSpan;

      expect(wordSpan.style!.fontSize, 28.0);
    },
  );

  testWidgets('renders with custom font size passed via parameter', (
    WidgetTester tester,
  ) async {
    // Arrange - custom font size via constructor
    const customFontSize = 18.0;

    const word1 = QuranWord(
      id: 1,
      position: 1,
      text: 'Word1',
      charTypeName: 'word',
      codeV1: 'Code1',
      // Pre-computed by data layer
      renderedText: 'Code1',
      fontFamily: 'QCF_P001',
      lineHeight: 1.6,
    );

    const ayah = PageAyahInfo(
      surahNumber: 1,
      ayahNumber: 1,
      text: 'Ayah Text',
      surahName: 'Surah Name',
      surahNameEnglish: 'Surah Name English',
      words: [word1],
    );

    const page = QuranPageEntity(pageNumber: 1, ayahs: [ayah], juz: 1, hizb: 1);

    // Act
    await tester.pumpWidget(
      createWidgetUnderTest(page, fontSize: customFontSize),
    );

    // Assert
    final Finder surahTextSectionFinder = find.byType(SurahTextSection);
    final Finder richTextFinder = find.descendant(
      of: surahTextSectionFinder,
      matching: find.byType(RichText),
    );

    final RichText richText = tester.widget<RichText>(richTextFinder);
    final textSpan = richText.text as TextSpan;
    final wordSpan = textSpan.children![0] as TextSpan;

    expect(wordSpan.style!.fontSize, customFontSize);
    expect(wordSpan.style!.fontFamily, 'QCF_P001'); // Pre-computed font family
  });

  testWidgets('renders with pre-computed custom font family', (
    WidgetTester tester,
  ) async {
    // Arrange - font family pre-computed by data layer
    const customFontFamily = 'Noto Nastaliq Urdu';

    const word1 = QuranWord(
      id: 1,
      position: 1,
      text: 'Word1',
      charTypeName: 'word',
      textUthmani: 'UthmaniText',
      // Pre-computed by data layer for non-QCF font
      renderedText: 'UthmaniText',
      fontFamily: customFontFamily,
      lineHeight: 2.2,
    );

    const ayah = PageAyahInfo(
      surahNumber: 1,
      ayahNumber: 1,
      text: 'Ayah Text',
      surahName: 'Surah Name',
      surahNameEnglish: 'Surah Name English',
      words: [word1],
    );

    const page = QuranPageEntity(pageNumber: 1, ayahs: [ayah], juz: 1, hizb: 1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest(page));

    // Assert - uses pre-computed font family
    final Finder surahTextSectionFinder = find.byType(SurahTextSection);
    final Finder richTextFinder = find.descendant(
      of: surahTextSectionFinder,
      matching: find.byType(RichText),
    );

    final RichText richText = tester.widget<RichText>(richTextFinder);
    final textSpan = richText.text as TextSpan;
    final wordSpan = textSpan.children![0] as TextSpan;

    expect(wordSpan.style!.fontFamily, customFontFamily);
  });
}
