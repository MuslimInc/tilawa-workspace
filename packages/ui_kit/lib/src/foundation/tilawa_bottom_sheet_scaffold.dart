import 'package:flutter/material.dart';

import '../atoms/tilawa_sheet_handle.dart';
import 'component_tokens.dart';
import 'tilawa_comfortable_reach_padding.dart';

/// Standard layout for modal bottom sheet content aligned with
/// [TilawaBottomSheetScaffoldTokens].
///
/// Use with [modalShape] and a matching surface on
/// [showTilawaModalBottomSheet] so the system sheet clip matches this chrome.
///
/// Place scrollable regions (e.g. [ListView] inside [Flexible]) in [children];
/// apply [resolvedBodyPadding] inside the scrollable viewport when the child
/// cannot be wrapped in [Padding] (e.g. when using [Flexible]).
///
/// When [footer] is set, it renders below [children] outside the scroll
/// viewport with comfortable thumb-zone spacing. Keyboard lift is owned by
/// the modal route / resized parent — footer uses [keyboardAware]: false
/// (same contract as [TilawaFormScreenScaffold] / ADR-009).
class TilawaBottomSheetScaffold extends StatelessWidget {
  const TilawaBottomSheetScaffold({
    super.key,
    this.showHandle = true,
    this.topBar,
    this.betweenTopBarAndBody = const <Widget>[],
    required this.children,
    this.footer,
  });

  final bool showHandle;

  /// Typically a title row; wrapped with [TilawaBottomSheetScaffoldTokens]
  /// [headerPadding].
  final Widget? topBar;

  /// Full-width widgets after [topBar] (e.g. [Divider]) without extra
  /// horizontal inset.
  final List<Widget> betweenTopBarAndBody;

  /// Remaining column children (e.g. [Flexible] + [ListView]).
  final List<Widget> children;

  /// Sticky actions below the scroll body (not scrolled with [children]).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.bottomSheetScaffold;
    final direction = Directionality.of(context);
    final footerPadding = tokens.footerPadding.resolve(direction);
    // Modal sheets / resized parents already lift for the IME — do not stack
    // [effectiveKeyboardInset] again (overflow while keyboard shows/dismisses).
    final bottomPadding = TilawaComfortableReachPadding.resolve(
      context,
      kind: TilawaComfortableReachKind.sheet,
      keyboardAware: false,
      keyboardBuffer: footerPadding.bottom,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showHandle) const TilawaSheetHandle(),
        if (topBar != null)
          Padding(
            padding: tokens.headerPadding,
            child: topBar,
          ),
        ...betweenTopBarAndBody,
        ...children,
        if (footer != null)
          Material(
            color: theme.colorScheme.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: tokens.footerTopBorderWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: footerPadding.copyWith(bottom: bottomPadding),
                  child: footer,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Shape for [showTilawaModalBottomSheet] and similar APIs.
  static ShapeBorder modalShape(BuildContext context) {
    final r = Theme.of(context).componentTokens.bottomSheetScaffold.topRadius;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
    );
  }

  /// Resolved [TilawaBottomSheetScaffoldTokens.bodyPadding] for the current
  /// directionality.
  static EdgeInsets resolvedBodyPadding(BuildContext context) {
    final g = Theme.of(context).componentTokens.bottomSheetScaffold.bodyPadding;
    return g.resolve(Directionality.of(context));
  }
}
