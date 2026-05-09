import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Placeholder layout while prayer times data is loading.
///
/// Mirrors the Today tab structure: location row, hero, prayer list, utilities.
class PrayerTimesScreenSkeleton extends StatelessWidget {
  const PrayerTimesScreenSkeleton({super.key});

  static const int _prayerRowCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: context.l10n.prayerTimesLoading,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: tokens.spaceMedium,
          bottom: tokens.spaceExtraLarge,
        ),
        children: [
          _SkeletonLocationCard(tokens: tokens, colorScheme: colorScheme),
          SizedBox(height: tokens.spaceSmall),
          _SkeletonHeroCard(tokens: tokens, colorScheme: colorScheme),
          _SkeletonPrayerListCard(tokens: tokens, colorScheme: colorScheme),
          _SkeletonBottomUtilities(tokens: tokens, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _SkeletonLocationCard extends StatelessWidget {
  const _SkeletonLocationCard({
    required this.tokens,
    required this.colorScheme,
  });

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusLarge,
        backgroundColor: colorScheme.surfaceContainerLowest,
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceSmall,
        ),
        child: Row(
          children: [
            TilawaSkeletonBlock(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              shape: TilawaSkeletonShape.circle,
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: TilawaSkeletonBlock(
                width: double.infinity,
                height: tokens.spaceMedium,
                borderRadius: tokens.radiusSmall,
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            TilawaSkeletonBlock(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              shape: TilawaSkeletonShape.circle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonHeroCard extends StatelessWidget {
  const _SkeletonHeroCard({required this.tokens, required this.colorScheme});

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusLarge,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TilawaSkeletonBlock(
                  width: tokens.spaceExtraLarge * 2,
                  height: tokens.spaceMedium,
                  borderRadius: tokens.radiusLarge,
                ),
                const Spacer(),
                TilawaSkeletonBlock(
                  width: tokens.spaceExtraLarge * 2.5,
                  height: tokens.spaceSmall,
                  borderRadius: tokens.radiusSmall,
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TilawaSkeletonBlock(
                width: tokens.spaceExtraLarge * 3,
                height: tokens.spaceSmall,
                borderRadius: tokens.radiusSmall,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Center(
              child: TilawaSkeletonBlock(
                width: tokens.spaceExtraLarge * 4,
                height: tokens.spaceLarge + tokens.spaceSmall,
                borderRadius: tokens.radiusSmall,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: TilawaSkeletonBlock(
                  width: double.infinity,
                  height: tokens.spaceSmall,
                  borderRadius: tokens.radiusSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPrayerListCard extends StatelessWidget {
  const _SkeletonPrayerListCard({
    required this.tokens,
    required this.colorScheme,
  });

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusLarge,
        backgroundColor: colorScheme.surface,
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          children: [
            for (var i = 0; i < PrayerTimesScreenSkeleton._prayerRowCount; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
                child: _SkeletonPrayerRow(tokens: tokens),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPrayerRow extends StatelessWidget {
  const _SkeletonPrayerRow({required this.tokens});

  final TilawaDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TilawaSkeletonBlock(
                width: double.infinity,
                height: tokens.spaceSmall + tokens.spaceExtraSmall,
                borderRadius: tokens.radiusSmall,
              ),
              SizedBox(height: tokens.spaceExtraSmall / 2),
              FractionallySizedBox(
                widthFactor: 0.45,
                alignment: AlignmentDirectional.centerStart,
                child: TilawaSkeletonBlock(
                  width: double.infinity,
                  height: tokens.spaceExtraSmall + 2,
                  borderRadius: tokens.radiusSmall,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        TilawaSkeletonBlock(
          width: tokens.spaceLarge + tokens.spaceSmall,
          height: tokens.spaceMedium,
          borderRadius: tokens.radiusSmall,
        ),
        SizedBox(width: tokens.spaceMedium),
        TilawaSkeletonBlock(
          width: tokens.iconSizeLarge,
          height: tokens.iconSizeLarge,
          shape: TilawaSkeletonShape.circle,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        TilawaSkeletonBlock(
          width: tokens.iconSizeLarge,
          height: tokens.iconSizeLarge,
          shape: TilawaSkeletonShape.circle,
        ),
      ],
    );
  }
}

class _SkeletonBottomUtilities extends StatelessWidget {
  const _SkeletonBottomUtilities({
    required this.tokens,
    required this.colorScheme,
  });

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: Column(
        children: [
          _SkeletonUtilityButton(tokens: tokens, colorScheme: colorScheme),
          SizedBox(height: tokens.spaceSmall),
          _SkeletonUtilityButton(tokens: tokens, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _SkeletonUtilityButton extends StatelessWidget {
  const _SkeletonUtilityButton({
    required this.tokens,
    required this.colorScheme,
  });

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      flat: true,
      borderRadius: tokens.radiusLarge,
      backgroundColor: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant.withValues(
        alpha: tokens.opacityMedium,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceSmall,
      ),
      child: Row(
        children: [
          TilawaSkeletonBlock(
            width: tokens.iconSizeSmall,
            height: tokens.iconSizeSmall,
            shape: TilawaSkeletonShape.circle,
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(
            child: TilawaSkeletonBlock(
              width: double.infinity,
              height: tokens.spaceMedium,
              borderRadius: tokens.radiusSmall,
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          TilawaSkeletonBlock(
            width: tokens.iconSizeMedium,
            height: tokens.iconSizeMedium,
            shape: TilawaSkeletonShape.rounded,
            borderRadius: tokens.radiusSmall,
          ),
        ],
      ),
    );
  }
}
