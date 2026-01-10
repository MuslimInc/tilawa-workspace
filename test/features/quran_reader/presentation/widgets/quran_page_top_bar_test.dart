import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/settings/quran_settings_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_page_top_bar.dart';

class MockQuranReaderBloc extends MockBloc<QuranReaderEvent, QuranReaderState>
    implements QuranReaderBloc {}

class MockQuranSettingsBloc
    extends MockBloc<QuranSettingsEvent, QuranSettingsState>
    implements QuranSettingsBloc {}

void main() {
  late MockQuranReaderBloc mockBloc;
  late MockQuranSettingsBloc mockSettingsBloc;

  setUp(() {
    mockBloc = MockQuranReaderBloc();
    mockSettingsBloc = MockQuranSettingsBloc();
    when(() => mockBloc.state).thenReturn(const QuranReaderState());
    when(() => mockSettingsBloc.state).thenReturn(const QuranSettingsState());
  });

  Widget createWidget(Widget child) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<QuranReaderBloc>.value(value: mockBloc),
          BlocProvider<QuranSettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: Scaffold(body: child),
      ),
    );
  }

  group('QuranPageTopBar', () {
    testWidgets('should display surah name and juz number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          const QuranPageTopBar(surahNameEnglish: 'Al-Fatiha', juzNumber: 1),
        ),
      );

      expect(find.text('Al-Fatiha'), findsOneWidget);
      expect(find.text('Part 1'), findsOneWidget);
    });

    testWidgets('should display text settings icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          const QuranPageTopBar(surahNameEnglish: 'Al-Baqara', juzNumber: 2),
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
      whenListen(
        mockSettingsBloc,
        Stream.fromIterable([const QuranSettingsState()]),
        initialState: const QuranSettingsState(),
      );

      await tester.pumpWidget(
        createWidget(
          const QuranPageTopBar(surahNameEnglish: 'Al-Baqara', juzNumber: 2),
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
        createWidget(
          const QuranPageTopBar(surahNameEnglish: 'Al-Kahf', juzNumber: 15),
        ),
      );

      expect(find.text('Al-Kahf'), findsOneWidget);
      expect(find.text('Part 15'), findsOneWidget);
    });
  });
}
