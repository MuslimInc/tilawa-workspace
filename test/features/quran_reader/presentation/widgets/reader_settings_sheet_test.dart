import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockOnSettingsChanged extends Mock {
  void call(ReaderSettingsEntity settings);
}

void main() {
  group('ReaderSettingsSheet', () {
    late MockOnSettingsChanged mockOnSettingsChanged;
    const initialSettings = ReaderSettingsEntity();

    setUp(() {
      mockOnSettingsChanged = MockOnSettingsChanged();
      registerFallbackValue(const ReaderSettingsEntity());
    });

    Widget buildTestWidget() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: ReaderSettingsSheet(
            settings: initialSettings,
            onSettingsChanged: mockOnSettingsChanged.call,
          ),
        ),
      );
    }

    testWidgets('should display settings options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsOneWidget);
      // Skip offstage because it might be in an Expanded/ListView that hasn't scrolled yet
      expect(
        find.text('Show Translation', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Show Ayah Numbers', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets(
      'should call onSettingsChanged when font size slider is changed',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final Finder slider = find.byType(Slider).first;
        await tester.drag(slider, const Offset(50, 0));
        await tester.pump();

        verify(() => mockOnSettingsChanged(any())).called(2);
      },
    );

    testWidgets('should call onSettingsChanged when switch is toggled', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the first switch, ensuring it's visible by scrolling if necessary
      final Finder listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();

      final Finder translationSwitch = find.byType(Switch).first;
      await tester.tap(translationSwitch);
      await tester.pump();

      verify(() => mockOnSettingsChanged(any())).called(1);
    });
  });
}
