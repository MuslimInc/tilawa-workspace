import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/tilawa_sheet_handle.dart';
import 'component_tokens.dart';
import 'safe_area_ext.dart';
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
///
/// Handle, title/close, and footer stay pinned. Only the body scrolls when
/// space is tight — never the full sheet chrome.
class TilawaBottomSheetScaffold extends StatelessWidget {
  const TilawaBottomSheetScaffold({
    super.key,
    this.showHandle = true,
    this.topBar,
    this.betweenTopBarAndBody = const <Widget>[],
    required this.children,
    this.footer,
  });

  /// Below this max-height, footer drops comfortable-reach extras so chrome
  /// (handle + title + actions) can still fit without overflowing.
  @visibleForTesting
  static const double tightHeightBreakpoint = 360;

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
    final double comfortableBottom = TilawaComfortableReachPadding.resolve(
      context,
      kind: TilawaComfortableReachKind.sheet,
      keyboardAware: false,
      keyboardBuffer: footerPadding.bottom,
    );

    final bool hasFlexChild = children.any(
      (Widget child) => child is Flexible || child is Expanded,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool hasBound =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final bool tight =
            hasBound && constraints.maxHeight < tightHeightBreakpoint;

        // Short viewports: keep system inset, drop spaceHuge / reach buffer so
        // handle + title/close + actions still fit with a sticky footer.
        final double footerBottom = tight
            ? math.max(
                footerPadding.bottom,
                context.effectiveSystemBottomSafeArea,
              )
            : comfortableBottom;

        final Widget? footerWidget = footer == null
            ? null
            : Material(
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
                      padding: footerPadding.copyWith(bottom: footerBottom),
                      child: footer,
                    ),
                  ),
                ),
              );

        final List<Widget> headerChildren = <Widget>[
          if (showHandle) const TilawaSheetHandle(),
          if (topBar != null)
            Padding(
              padding: tokens.headerPadding,
              child: topBar,
            ),
          ...betweenTopBarAndBody,
        ];

        final List<Widget> bodyChildren;
        if (hasFlexChild) {
          bodyChildren = children;
        } else if (hasBound) {
          // Compact action sheets: scroll tiles only; pin handle / title / footer.
          bodyChildren = <Widget>[
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ];
        } else {
          bodyChildren = children;
        }

        final Widget column = Column(
          mainAxisSize: hasBound ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...headerChildren,
            ...bodyChildren,
            ?footerWidget,
          ],
        );

        if (!hasBound) {
          return column;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight),
          child: column,
        );
      },
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
