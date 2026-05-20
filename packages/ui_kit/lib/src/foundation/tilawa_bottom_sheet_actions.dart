import 'package:flutter/material.dart';

import '../atoms/tilawa_button.dart';
import 'component_tokens.dart';

/// Primary and optional secondary actions for [TilawaBottomSheetScaffold.footer].
///
/// Stacks vertically on narrow widths; places primary on the trailing end in
/// horizontal layouts (start edge under RTL).
class TilawaBottomSheetActions extends StatelessWidget {
  const TilawaBottomSheetActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryLoading = false,
    this.primaryVariant = TilawaButtonVariant.primary,
    this.secondaryVariant = TilawaButtonVariant.outline,
    this.stackBreakpoint = 360,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool primaryLoading;
  final TilawaButtonVariant primaryVariant;
  final TilawaButtonVariant secondaryVariant;

  /// Below this width, actions stack with primary below secondary.
  final double stackBreakpoint;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.bottomSheetScaffold;
    final gap = tokens.footerActionGap;
    final primary = TilawaButton(
      text: primaryLabel,
      onPressed: onPrimary,
      isLoading: primaryLoading,
      variant: primaryVariant,
      isFullWidth: true,
    );

    if (secondaryLabel == null) {
      return primary;
    }

    final secondary = TilawaButton(
      text: secondaryLabel!,
      onPressed: onSecondary,
      variant: secondaryVariant,
      isFullWidth: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < stackBreakpoint;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [secondary, primary],
          );
        }

        return Row(
          spacing: gap,
          children: [
            Expanded(child: secondary),
            Expanded(child: primary),
          ],
        );
      },
    );
  }
}
