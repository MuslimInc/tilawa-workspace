import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/presentation/widgets/tasbeeh/tasbeeh_counter_card.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrapCounterCard({
  required Widget child,
  double height = 180,
  double width = 360,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Scaffold(
        body: SizedBox(
          height: height,
          width: width,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('quick count card fits short viewport without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapCounterCard(
        child: TasbeehCounterCard(
          displayCount: 42,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tap anywhere to increment'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('saved dhikr counter card fits short viewport without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapCounterCard(
        child: TasbeehCounterCard(
          displayCount: 7,
          targetCount: 33,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tap anywhere to increment'), findsOneWidget);
    expect(find.text('7 / 33'), findsOneWidget);
  });

  testWidgets('counter card scales down with increased text scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapCounterCard(
        height: 220,
        textScaler: const TextScaler.linear(1.8),
        child: TasbeehCounterCard(
          displayCount: 12,
          targetCount: 99,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
