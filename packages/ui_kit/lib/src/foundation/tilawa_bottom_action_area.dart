import 'package:flutter/material.dart';

import 'component_tokens.dart';
import 'content_bounds.dart';
import 'tilawa_comfortable_reach_padding.dart';

/// Sticky full-screen footer chrome for primary bottom actions.
///
/// Mirrors [TilawaBottomSheetScaffold]'s footer band (surface, top border,
/// comfortable bottom spacing) for [Scaffold] bodies. Pair with
/// [TilawaFormScreenScaffold] or place at the bottom of a [Column].
class TilawaBottomActionArea extends StatelessWidget {
  /// Creates a sticky bottom action band.
  const TilawaBottomActionArea({
    super.key,
    required this.child,
    this.top = 0,
    this.horizontal,
    this.extraBottom = 0,
    this.keyboardAware = true,
    this.showTopBorder = true,
    this.maxWidthKind,
  });

  /// Primary controls (buttons, indicators, footer chrome).
  final Widget child;

  /// Space above [child] inside the padded region.
  final double top;

  /// Horizontal inset; defaults to sheet footer horizontal padding.
  final double? horizontal;

  /// Additional bottom clearance (shell nav, mini-player, FAB stack).
  final double extraBottom;

  /// When true, lifts content above the software keyboard.
  final bool keyboardAware;

  /// When true, draws the same top divider as sheet footers.
  final bool showTopBorder;

  /// When set, constrains [child] via [TilawaContentBounds.resolveMaxWidth].
  final TilawaContentKind? maxWidthKind;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaBottomSheetScaffoldTokens sheetTokens =
        theme.componentTokens.bottomSheetScaffold;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsets footerPadding = sheetTokens.footerPadding.resolve(
      direction,
    );
    final double side = horizontal ?? footerPadding.left;
    final double bottom =
        TilawaComfortableReachPadding.resolve(
          context,
          kind: TilawaComfortableReachKind.screen,
          keyboardAware: keyboardAware,
        ) +
        extraBottom;

    Widget content = child;
    if (maxWidthKind != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: TilawaContentBounds.resolveMaxWidth(
              context,
              maxWidthKind!,
            ),
          ),
          child: content,
        ),
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: showTopBorder
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: sheetTokens.footerTopBorderWidth,
                  ),
                ),
              )
            : const BoxDecoration(),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              top + footerPadding.top,
              side,
              bottom,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
