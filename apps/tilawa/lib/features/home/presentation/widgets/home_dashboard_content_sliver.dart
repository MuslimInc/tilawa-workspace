import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_sliver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home content canvas below the hero.
///
/// Travel-app lip: rounded top sheet overlapping the hero gradient with a soft
/// shadow (Ronas IT–style panel; tokens only — no new palette).
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
    final BorderRadius sheetRadius = BorderRadius.vertical(
      top: Radius.circular(tokens.radiusExtraLarge),
    );

    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -HomeDashboardHeroSliver.sheetOverlap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: sheetRadius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: tokens.opacityShadow,
                ),
                blurRadius: tokens.blurShadow,
                offset: Offset(0, tokens.shadowOffsetMedium.dy * -0.5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: sheetRadius,
            child: _HomeDashboardSheetBody(
              color: sheetColor,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardSheetBody extends StatelessWidget {
  const _HomeDashboardSheetBody({
    required this.color,
    required this.child,
  });

  final Color color;
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
            tokens.spaceMedium,
            tokens.spaceMedium,
            TilawaShellPadding.of(context) + tokens.spaceMedium,
          ),
          child: child,
        ),
      ),
    );
  }
}
