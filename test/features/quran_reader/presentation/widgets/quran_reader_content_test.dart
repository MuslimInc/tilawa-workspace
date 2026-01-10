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
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_content.dart';

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
      () => mockQuranSettingsBloc.state,
    ).thenReturn(const QuranSettingsState());
    when(
      () => mockWordByWordAudioBloc.state,
    ).thenReturn(const WordByWordAudioState());
  });

  Widget createWidgetUnderTest(
    List<QuranPageEntity> pages,
    PageController pageController,
    Function(int)? onPageChanged, {
    double fontSize = 28.0,
  }) {
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
          body: QuranReaderContent(
            pages: pages,
            pageController: pageController,
            fontSize: fontSize,
            onPageChanged: onPageChanged,
          ),
        ),
      ),
    );
  }

  group('QuranReaderContent', () {
    testWidgets('renders PageView with QuranPageWidgets', (
      WidgetTester tester,
    ) async {
      // Arrange
      const page1 = QuranPageEntity(pageNumber: 1, ayahs: [], juz: 1, hizb: 1);
      const page2 = QuranPageEntity(pageNumber: 2, ayahs: [], juz: 1, hizb: 1);
      final pages = [page1, page2];
      final pageController = PageController();

      // Act
      await tester.pumpWidget(
        createWidgetUnderTest(pages, pageController, null),
      );

      // Assert
      expect(find.byType(PageView), findsOneWidget);
      expect(
        find.byType(QuranPageWidget),
        findsOneWidget,
      ); // Only 1 built initially due to viewport
    });

    testWidgets('calls onPageChanged when page updates', (
      WidgetTester tester,
    ) async {
      // Arrange
      const page1 = QuranPageEntity(pageNumber: 1, ayahs: [], juz: 1, hizb: 1);
      const page2 = QuranPageEntity(pageNumber: 2, ayahs: [], juz: 1, hizb: 1);
      final pages = [page1, page2];
      final pageController = PageController();
      int? changedPage;

      // Act
      await tester.pumpWidget(
        createWidgetUnderTest(pages, pageController, (index) {
          changedPage = index;
        }),
      );

      // Swipe to next page
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Assert
      expect(changedPage, 1); // Index 1 is page 2
    });
  });
}
