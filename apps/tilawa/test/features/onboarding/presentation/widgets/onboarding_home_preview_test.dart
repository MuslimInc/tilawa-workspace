import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_hero_visual.dart';
import 'package:tilawa/features/onboarding/presentation/widgets/onboarding_home_preview.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  ThemeData theme() => AppTheme.getLightTheme(
    primaryColor: PrimaryColorPreset.defaultPreset.value,
  );

  Future<void> pumpPreview(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 400,
              child: OnboardingHeroVisual(
                assetPath: '',
                style: OnboardingHeroStyle.devicePreview,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders Home preview with shared tiles and no Image.asset', (
    WidgetTester tester,
  ) async {
    await pumpPreview(tester);

    expect(find.byType(OnboardingHomePreview), findsOneWidget);
    expect(find.byType(HomePrimaryActionTile), findsNWidgets(2));
    expect(find.byType(AbsorbPointer), findsWidgets);
    expect(find.byType(Image), findsNothing);

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.homeGreeting), findsOneWidget);
    expect(find.text('Ahmad'), findsOneWidget);
    expect(find.text(l10n.homeQuickToolsTitle), findsOneWidget);
    expect(find.text(l10n.bottomNavHome), findsOneWidget);
    expect(find.textContaining('04:07'), findsOneWidget);
  });

  testWidgets('ignores taps on preview controls', (WidgetTester tester) async {
    await pumpPreview(tester);

    await tester.tap(
      find.byType(AbsorbPointer).first,
      warnIfMissed: false,
    );
    await tester.pump();

    // Still mounted; AbsorbPointer swallowed the gesture.
    expect(find.byType(OnboardingHomePreview), findsOneWidget);
  });
}
