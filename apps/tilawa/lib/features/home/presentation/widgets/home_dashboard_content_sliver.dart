import 'package:flutter/material.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home content canvas below the hero.
///
/// Flat content sheet below the hero — no negative translate overlap.
class HomeDashboardContentSliver extends StatelessWidget {
  const HomeDashboardContentSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = context.tokens;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final Color sheetColor = cardTokens.travelSheetSurface;
    final bool variantB =
        HomeDashboardHeroSliver.activeVariant(context) ==
        HomeHeroDesignVariant.b;
    final double topPadding = variantB
        ? tokens.spaceSmall
        : cardTokens.headerWaveAmplitude * 0.15;

    return SliverToBoxAdapter(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: variantB
              ? BorderRadius.vertical(
                  top: Radius.circular(tokens.radiusExtraLarge),
                )
              : null,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: tokens.opacityShadow * (variantB ? 0.45 : 0.35),
              ),
              blurRadius: tokens.blurShadow * (variantB ? 0.65 : 0.5),
              offset: Offset(0, tokens.shadowOffsetSmall.dy * -0.25),
            ),
          ],
        ),
        child: _HomeDashboardSheetBody(
          color: sheetColor,
          topPadding: topPadding,
          child: child,
        ),
      ),
    );
  }
}

class _HomeDashboardSheetBody extends StatelessWidget {
  const _HomeDashboardSheetBody({
    required this.color,
    required this.topPadding,
    required this.child,
  });

  final Color color;
  final double topPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ColoredBox(
      color: color,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMedium,
            topPadding,
            tokens.spaceMedium,
            TilawaShellPadding.of(context) + tokens.spaceMedium,
          ),
          child: child,
        ),
      ),
    );
  }
}
