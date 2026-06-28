import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../lib/src/previews/preview_wrapper.dart';
import 'golden_constraints.dart';

const List<TilawaNavDestination> _kBehancePhoneNavDestinations =
    <TilawaNavDestination>[
      TilawaNavDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      TilawaNavDestination(
        label: 'Quran',
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
      ),
      TilawaNavDestination(
        label: 'Qibla',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
      ),
      TilawaNavDestination(
        label: 'Athkar',
        icon: Icons.auto_stories_outlined,
        activeIcon: Icons.auto_stories_rounded,
      ),
    ];

Widget _featuredGradientCard(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TilawaHomeDashboardCardTokens cardTokens =
      theme.componentTokens.homeDashboardCard;
  final MeMuslimDesignTokens tokens = theme.tokens;
  final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);

  return SizedBox(
    width: 340,
    child: TilawaCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      borderRadius: radius,
      borderWidth: 0,
      surface: TilawaCardSurface.raised,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              cardTokens.gradientStart,
              cardTokens.gradientEnd,
            ],
          ),
        ),
        child: Padding(
          padding: theme.componentTokens.card.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last Read',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cardTokens.foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                'Surah Al-Baqarah',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: cardTokens.foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _instructionChip(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  final MeMuslimDesignTokens tokens = theme.tokens;

  return SizedBox(
    width: 340,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium,
        ),
        child: Text(
          'Rotate the phone 44° to the left',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Behance lifestyle pattern goldens', () {
    goldenTest(
      'BehanceFeaturedCard',
      fileName: 'organisms/behance_featured_card',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: TilawaPreviewWrapper(
              child: Builder(builder: _featuredGradientCard),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'BehanceInstructionChip',
      fileName: 'organisms/behance_instruction_chip',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: TilawaPreviewWrapper(
              child: Builder(builder: _instructionChip),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'BehancePhoneBottomNav',
      fileName: 'organisms/behance_phone_bottom_nav',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(
          minWidth: 800,
          maxWidth: 800,
          minHeight: 48,
          maxHeight: 900,
        ),
        children: [
          GoldenTestScenario(
            name: 'Qibla selected',
            child: MaterialApp(
              theme: AppTheme.getLightTheme(
                primaryColor: AppColors.defaultPrimary,
              ),
              home: MediaQuery(
                data: const MediaQueryData(size: Size(390, 820)),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 390,
                    height: 200,
                    child: TilawaAdaptiveShell(
                      destinations: _kBehancePhoneNavDestinations,
                      selectedIndex: 2,
                      onDestinationSelected: (_) {},
                      bottomPlayer: const SizedBox.shrink(),
                      child: const ColoredBox(color: AppColors.lightCanvas),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
