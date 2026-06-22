import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('renders prayer-period gradient without photo asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            width: 360,
            child: HomeHeroBackground(
              heroTokens: TilawaHomeNextPrayerHeroTokens.day(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeHeroBackground), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(DecoratedBox), findsWidgets);
  });
}
