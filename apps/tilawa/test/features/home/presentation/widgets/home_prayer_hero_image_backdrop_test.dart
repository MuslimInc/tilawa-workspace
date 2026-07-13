import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/constants/home_hero_assets.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_image_backdrop.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('loads spiritual wallpaper with monochrome treatment', (
    tester,
  ) async {
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
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('prayer'), findsOneWidget);
  });

  testWidgets('skeleton path skips the photo layer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            width: 360,
            child: HomePrayerHeroImageBackdrop(
              showImage: false,
              builder: (context, style) {
                expect(style.imageVisible, isFalse);
                expect(style.ink, AppColors.tripGlideInk);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
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

  testWidgets('does not paint decorative mosque watermark over architecture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            width: 360,
            child: HomePrayerHeroImageBackdrop(
              builder: (context, style) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byIcon(Icons.mosque_outlined), findsNothing);
  });

  test('image foreground style uses cream ink for contrast on green wash', () {
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
