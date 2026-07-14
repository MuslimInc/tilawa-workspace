import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/constants/home_hero_assets.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_image_backdrop.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('loads wallpaper with desaturate treatment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              height: 220,
              width: 360,
              child: HomePrayerHeroImageBackdrop(
                builder: (context, style) => Text(
                  'prayer',
                  style: TextStyle(color: style.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('prayer'), findsOneWidget);
  });

  testWidgets('skeleton path skips the photo layer', (tester) async {
    final theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SizedBox(
            height: 220,
            width: 360,
            child: HomePrayerHeroImageBackdrop(
              showImage: false,
              builder: (context, style) {
                expect(style.imageVisible, isFalse);
                expect(style.ink, theme.colorScheme.onSurface);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byType(ColorFiltered), findsNothing);
  });

  test(
    'wallpaper focal alignment keeps architecture on visual left in RTL',
    () {
      expect(
        HomeHeroAssets.wallpaperFocalAlignment(TextDirection.rtl),
        const Alignment(0.82, -0.76),
      );
      expect(
        HomeHeroAssets.wallpaperFocalAlignment(TextDirection.ltr),
        const Alignment(-0.82, -0.76),
      );
    },
  );

  test('image foreground style uses cream ink for contrast on photo', () {
    final theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );
    final style = HomePrayerHeroForegroundStyle.image(
      screenTokens: theme.componentTokens.homeScreen,
    );

    expect(style.ink, AppColors.homeNextPrayerGradientNightForeground);
    expect(style.imageVisible, isTrue);
  });
}
