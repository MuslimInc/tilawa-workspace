import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
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
              screenTokens: AppTheme.getLightTheme(
                primaryColor: AppColors.defaultPrimary,
              ).componentTokens.homeScreen,
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

  test('day gradient stops differ for visible phase ramp', () {
    final tokens = TilawaHomeNextPrayerHeroTokens.day();

    expect(
      tokens.gradientTopStart,
      isNot(equals(tokens.gradientBottomEnd)),
    );
    expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientTop);
    expect(tokens.gradientBottomEnd, AppColors.homeNextPrayerGradientBottom);
  });

  test('system overlay uses dark icons on light day gradient', () {
    final style = HomeHeroBackground.systemOverlayStyle(
      TilawaHomeNextPrayerHeroTokens.day(),
    );

    expect(style.statusBarIconBrightness, Brightness.dark);
  });

  test('system overlay uses dark icons on pre-dawn gradient', () {
    final style = HomeHeroBackground.systemOverlayStyle(
      TilawaHomeNextPrayerHeroTokens.preDawn(),
    );

    expect(style.statusBarIconBrightness, Brightness.dark);
  });

  test('system overlay uses light icons on night gradient', () {
    final style = HomeHeroBackground.systemOverlayStyle(
      TilawaHomeNextPrayerHeroTokens.night(),
    );

    expect(style.statusBarIconBrightness, Brightness.light);
  });

  test('pre-dawn hero uses dark chrome ink not cream foreground', () {
    final tokens = TilawaHomeNextPrayerHeroTokens.preDawn();

    expect(HomeHeroPhotoTheme.isDarkHero(tokens), isFalse);
    expect(
      HomeHeroPhotoTheme.heroChromeInk(tokens),
      AppColors.homeNextPrayerGradientForeground,
    );
  });
}
