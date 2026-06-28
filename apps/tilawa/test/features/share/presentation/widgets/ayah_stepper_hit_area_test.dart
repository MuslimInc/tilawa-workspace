import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/widgets/share_composer_widgets.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Widget buildSubject({
    int value = 5,
    int min = 1,
    int max = 10,
    ValueChanged<int>? onChanged,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
      home: Scaffold(
        body: Center(
          child: AyahStepper(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('each stepper button hit area is at least 48x48 dp', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final inkWells = find.descendant(
      of: find.byType(AyahStepper),
      matching: find.byType(InkWell),
    );
    expect(inkWells, findsNWidgets(2));

    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(inkWells.at(i));
      expect(
        size.width,
        greaterThanOrEqualTo(48),
        reason: 'InkWell at index $i width must be >= 48dp',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(48),
        reason: 'InkWell at index $i height must be >= 48dp',
      );
    }
  });

  testWidgets('tapping the outer hit area fires the increment callback', (
    tester,
  ) async {
    var receivedValue = -1;
    await tester.pumpWidget(
      buildSubject(value: 5, onChanged: (v) => receivedValue = v),
    );
    await tester.pump();

    final addButton = find.descendant(
      of: find.byType(AyahStepper),
      matching: find.widgetWithIcon(InkWell, Icons.add_rounded),
    );
    expect(addButton, findsOneWidget);

    final center = tester.getCenter(addButton);
    // Tap 22px right of center: inside the 48-diameter InkWell circle
    // (radius 24) but outside the visible 36x36 icon box (which extends
    // only 18px from center). This proves the expanded hit area works.
    await tester.tapAt(center + const Offset(22, 0));
    await tester.pump();

    expect(
      receivedValue,
      6,
      reason:
          'Tap landed inside the expanded hit area but outside the '
          'visible 36x36 icon and should have triggered increment.',
    );
  });
}
