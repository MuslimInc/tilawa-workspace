import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_page_top_bar.dart';

class MockQuranReaderBloc extends MockBloc<QuranReaderEvent, QuranReaderState>
    implements QuranReaderBloc {}

void main() {
  late MockQuranReaderBloc mockBloc;

  setUp(() {
    mockBloc = MockQuranReaderBloc();
    when(() => mockBloc.state).thenReturn(const QuranReaderState());
  });

  group('QuranPageTopBar', () {
    testWidgets('should display surah name and juz number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<QuranReaderBloc>.value(
            value: mockBloc,
            child: const Scaffold(
              body: QuranPageTopBar(
                surahNameEnglish: 'Al-Fatiha',
                juzNumber: 1,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Al-Fatiha'), findsOneWidget);
      expect(find.text('Part 1'), findsOneWidget);
    });

    testWidgets('should display text settings icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<QuranReaderBloc>.value(
            value: mockBloc,
            child: const Scaffold(
              body: QuranPageTopBar(
                surahNameEnglish: 'Al-Baqara',
                juzNumber: 2,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('should open text settings sheet when icon tapped', (
      WidgetTester tester,
    ) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([const QuranReaderState()]),
        initialState: const QuranReaderState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<QuranReaderBloc>.value(
            value: mockBloc,
            child: const Scaffold(
              body: QuranPageTopBar(
                surahNameEnglish: 'Al-Baqara',
                juzNumber: 2,
              ),
            ),
          ),
        ),
      );

      // Tap the text settings icon
      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with "Text Size" label
      expect(find.text('Text Size'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should show different juz numbers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<QuranReaderBloc>.value(
            value: mockBloc,
            child: const Scaffold(
              body: QuranPageTopBar(surahNameEnglish: 'Al-Kahf', juzNumber: 15),
            ),
          ),
        ),
      );

      expect(find.text('Al-Kahf'), findsOneWidget);
      expect(find.text('Part 15'), findsOneWidget);
    });
  });
}
