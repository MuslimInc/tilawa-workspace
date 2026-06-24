import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_variant_b.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  tearDown(() {
    HomeHeroVariantDebug.resetForTests();
  });

  testWidgets('buildSlivers uses compact B overlap by default in debug', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (context) {
            expect(
              HomeDashboardHeroSliver.activeVariant(context),
              HomeHeroDesignVariant.b,
            );
            expect(
              HomeDashboardHeroSliver.contentSheetOverlap(context),
              HomeDashboardHeroVariantB.contentSheetOverlap(context),
            );
            return CustomScrollView(
              slivers: [
                HomeDashboardContentSliver(
                  child: const Text('body'),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('buildSlivers uses variant A wave overlap when debug is A', (
    tester,
  ) async {
    HomeHeroVariantDebug.variant.value = HomeHeroDesignVariant.a;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (context) {
            final double waveAmplitude =
                HomeDashboardHeroSliver.headerWaveAmplitude(context);
            expect(
              HomeDashboardHeroSliver.contentSheetOverlap(context),
              HomeDashboardHeroSliver.heroWaveOverlap(waveAmplitude),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
