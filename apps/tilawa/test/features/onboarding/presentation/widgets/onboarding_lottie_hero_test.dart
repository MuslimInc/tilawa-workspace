import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_hero_visual.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ThemeData theme() => AppTheme.getLightTheme(
    primaryColor: PrimaryColorPreset.defaultPreset.value,
  );

  Future<void> pumpHero(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        home: MediaQuery(
          data: const MediaQueryData().copyWith(
            disableAnimations: disableAnimations,
          ),
          child: const Scaffold(
            body: Center(
              child: OnboardingHeroVisual(
                assetPath: 'assets/lottie/muslim_man_praying_mosque.json',
                style: OnboardingHeroStyle.lottie,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders Lottie hero and plays once by default', (
    WidgetTester tester,
  ) async {
    await pumpHero(tester);

    final Lottie lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.repeat, isFalse);
    expect(lottie.animate, isTrue);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('freezes Lottie under reduced motion', (
    WidgetTester tester,
  ) async {
    await pumpHero(tester, disableAnimations: true);

    final Lottie lottie = tester.widget<Lottie>(find.byType(Lottie));
    expect(lottie.animate, isFalse);
    expect(lottie.repeat, isFalse);
  });
}
