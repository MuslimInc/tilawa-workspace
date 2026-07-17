import 'package:flutter/material.dart';
import 'package:tilawa/core/layout/home_dashboard_scroll_padding.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Dashboard sections on a TripGlide-style sheet below the prayer hero.
///
/// Rounded top edge sits on the hero fade; cards use spacing and contrast on
/// the sheet surface.
class HomeDashboardContentSliver extends StatelessWidget {
  const HomeDashboardContentSliver({
    super.key,
    required this.child,
    this.topPadding,
  });

  final Widget child;
  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);
    final BorderRadius sheetRadius = BorderRadius.vertical(
      top: Radius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.hero),
      ),
    );

    return SliverToBoxAdapter(
      child: DecoratedBox(
        decoration: screenTokens.contentSheetDecoration(
          tokens: tokens,
          colorScheme: theme.colorScheme,
          borderRadius: sheetRadius,
        ),
        child: _HomeDashboardSheetBody(
          horizontalInset: horizontalInset,
          topPadding: topPadding ?? tokens.spaceLarge,
          child: child,
        ),
      ),
    );
  }
}

class _HomeDashboardSheetBody extends StatelessWidget {
  const _HomeDashboardSheetBody({
    required this.horizontalInset,
    required this.topPadding,
    required this.child,
  });

  final double horizontalInset;
  final double topPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        topPadding,
        horizontalInset,
        homeDashboardScrollBottomPadding(context),
      ),
      child: child,
    );
  }
}
