import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/features/tour_guide/presentation/widgets/tour_tooltip_card.dart';

void main() {
  testWidgets('TourTooltipCard exposes semantics and actions', (tester) async {
  var nextTapped = false;
  var skipTapped = false;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
      home: Scaffold(
        body: Center(
          child: TourTooltipCard(
            title: 'Search reciters',
            description: 'Find your favourite voice quickly.',
            stepSemanticsLabel: 'Tour step 1 of 2',
            primaryActionLabel: 'Next',
            onPrimaryAction: () => nextTapped = true,
            skipLabel: 'Skip',
            onSkip: () => skipTapped = true,
            showSkip: true,
          ),
        ),
      ),
    ),
  );

  expect(find.text('Search reciters'), findsOneWidget);
  expect(find.text('Next'), findsOneWidget);
  expect(find.text('Skip'), findsOneWidget);

  await tester.tap(find.text('Next'));
  expect(nextTapped, isTrue);

  await tester.tap(find.text('Skip'));
  expect(skipTapped, isTrue);
  });
}
