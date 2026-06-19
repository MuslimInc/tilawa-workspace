import 'package:flutter/material.dart';

import 'content_bounds.dart';
import 'design_tokens.dart';
import 'safe_area_ext.dart';

/// Tokenised inset for primary bottom actions (footers, sheet actions, CTAs).
///
/// Combines horizontal content bounds, optional top offset, and
/// design-aware bottom spacing ([TilawaSafeAreaX.floatingBottomPadding]) so
/// controls clear the home indicator and land in a comfortable thumb zone.
///
/// Use inside [TilawaThumbReachLayout.actions], sheet footers, or any pinned
/// bottom column. For shell-hosted screens, add [extraBottom] to clear nav /
/// mini-player chrome ([TilawaShellPadding]).
class TilawaBottomActionInset extends StatelessWidget {
  /// Creates a bottom-action inset wrapper.
  const TilawaBottomActionInset({
    super.key,
    required this.child,
    this.top = 0,
    this.horizontal,
    this.minBottom,
    this.extraBottom = 0,
    this.keyboardAware = false,
    this.maxWidthKind,
  });

  /// Primary controls (buttons, indicators, footer chrome).
  final Widget child;

  /// Space above [child], e.g. offset within a thumb-reach action band.
  final double top;

  /// Horizontal inset; defaults to [TilawaDesignTokens.spaceLarge].
  final double? horizontal;

  /// Minimum bottom spacing when the device reports no system inset.
  final double? minBottom;

  /// Additional bottom clearance (shell nav, mini-player, FAB stack).
  final double extraBottom;

  /// When true, uses [TilawaSafeAreaX.keyboardAwareBottomPadding].
  final bool keyboardAware;

  /// When set, constrains [child] via [TilawaContentBounds.resolveMaxWidth].
  final TilawaContentKind? maxWidthKind;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
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

    final double side = horizontal ?? tokens.spaceLarge;
    final double bottom = _resolveBottom(context, tokens) + extraBottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(side, top, side, bottom),
      child: content,
    );
  }

  double _resolveBottom(BuildContext context, TilawaDesignTokens tokens) {
    if (keyboardAware) {
      return context.keyboardAwareBottomPadding;
    }
    if (minBottom != null) {
      return context.floatingBottomPaddingWithMin(minBottom!);
    }
    return context.floatingBottomPadding;
  }
}
