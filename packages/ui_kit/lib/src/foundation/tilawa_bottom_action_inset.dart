import 'dart:math' as math;

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

  /// Horizontal inset; defaults to [MeMuslimDesignTokens.bottomActionHorizontalInset].
  final double? horizontal;

  /// Minimum bottom spacing when the device reports no system inset.
  ///
  /// Folded into the base padding, so it is respected when the keyboard is
  /// hidden and relaxed (home-indicator clearance is moot) while it is open.
  final double? minBottom;

  /// Additional bottom clearance (shell nav, mini-player, FAB stack).
  final double extraBottom;

  /// Lifts the child by the full keyboard inset plus a small buffer, like
  /// [TilawaSafeAreaX.keyboardAwareBottomPadding] but also honoring [minBottom].
  ///
  /// Leave `false` inside a resizing [Scaffold] (the default): the ancestor
  /// resize already lifts the content, so only a small residual is added. Set
  /// `true` only in non-resizing hosts where this widget must clear the keyboard
  /// itself; otherwise the child would be double-lifted.
  final bool keyboardAware;

  /// When set, constrains [child] via [TilawaContentBounds.resolveMaxWidth].
  final TilawaContentKind? maxWidthKind;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
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

    final double side = horizontal ?? tokens.bottomActionHorizontalInset;
    final double bottom = _resolveBottom(context, tokens) + extraBottom;

    return AnimatedPadding(
      duration: tokens.durationFast,
      curve: tokens.curveEmphasized,
      padding: EdgeInsets.fromLTRB(side, top, side, bottom),
      child: content,
    );
  }

  double _resolveBottom(BuildContext context, MeMuslimDesignTokens tokens) {
    final double basePadding = minBottom != null
        ? context.floatingBottomPaddingWithMin(minBottom!)
        : context.floatingBottomPadding;

    if (keyboardAware) {
      return math.max(
        basePadding,
        context.effectiveKeyboardInset + tokens.spaceSmall,
      );
    }

    final double targetTotal = math.max(
      basePadding,
      context.effectiveKeyboardInset + tokens.spaceMedium,
    );

    return math.max(0.0, targetTotal - context.effectiveKeyboardInset);
  }
}
