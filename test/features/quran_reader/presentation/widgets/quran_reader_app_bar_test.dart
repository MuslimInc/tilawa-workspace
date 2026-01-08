import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_app_bar.dart';

void main() {
  group('QuranReaderAppBar', () {
    late bool backPressed;
    late bool searchPressed;
    late bool settingsPressed;

    setUp(() {
      backPressed = false;
      searchPressed = false;
      settingsPressed = false;
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: QuranReaderAppBar(
              title: 'Al-Fatiha',
              subtitle: 'The Opening',
              onBack: () => backPressed = true,
              onSearch: () => searchPressed = true,
              onSettings: () => settingsPressed = true,
            ),
          ),
        ),
      );
    }

    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Al-Fatiha'), findsOneWidget);
      expect(find.text('The Opening'), findsOneWidget);
    });

    testWidgets('should call onBack when back button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backPressed, isTrue);
    });

    testWidgets('should call onSearch when search button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.search_rounded));
      expect(searchPressed, isTrue);
    });

    testWidgets('should call onSettings when settings button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(settingsPressed, isTrue);
    });
  });
}
