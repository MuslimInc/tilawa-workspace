import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Dashboard sections on the neutral Home canvas.
///
/// Cards float on the gray canvas with soft elevation — no overlapping sheet.
class HomeDashboardContentSliver extends StatelessWidget {
  const HomeDashboardContentSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);

    return SliverToBoxAdapter(
      child: _HomeDashboardSheetBody(
        horizontalInset: horizontalInset,
        topPadding: tokens.spaceMedium,
        child: child,
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
    final tokens = context.tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          topPadding,
          horizontalInset,
          TilawaShellPadding.of(context) + tokens.spaceMedium,
        ),
        child: child,
      ),
    );
  }
}
