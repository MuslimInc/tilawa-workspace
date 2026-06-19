import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home content canvas below the hero.
class HomeDashboardContentSliver extends StatelessWidget {
  const HomeDashboardContentSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color sheetColor = context.scaffoldCanvasColor;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _HomeDashboardSheetBody(
            color: sheetColor,
            child: child,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          fillOverscroll: true,
          child: ColoredBox(color: sheetColor),
        ),
      ],
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceMedium,
          tokens.spaceMedium,
          tokens.spaceMedium,
          TilawaShellPadding.of(context) + tokens.spaceLarge,
        ),
        child: child,
      ),
    );
  }
}
