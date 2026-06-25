import 'package:flutter/material.dart';
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
    final MeMuslimDesignTokens tokens = context.tokens;
    // Soft grey canvas between premium section shells (Money Loop rhythm).
    final Color sheetColor = colorScheme.surfaceContainerLow;
    final double topPadding = tokens.spaceSmall;

    return SliverToBoxAdapter(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sheetColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: tokens.opacityShadow * 0.65,
              ),
              blurRadius: tokens.blurShadow,
              offset: Offset(0, tokens.shadowOffsetSmall.dy * -0.5),
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
