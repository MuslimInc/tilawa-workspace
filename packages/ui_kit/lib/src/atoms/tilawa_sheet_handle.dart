import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Decorative drag pill shown at the top of modal bottom sheets.
///
/// When [enableDragToDismiss] is true (default), a downward fling on the handle
/// calls [onDismiss] or [Navigator.maybePop] so the sheet can be dismissed from
/// the thumb zone (FR-005).
class TilawaSheetHandle extends StatelessWidget {
  const TilawaSheetHandle({
    super.key,
    this.showHandle = true,
    this.width,
    this.height,
    this.margin,
    this.color,
    this.omitTopMargin = false,
    this.enableDragToDismiss = true,
    this.onDismiss,
    this.semanticLabel,
  });

  final bool showHandle;
  final double? width;
  final double? height;

  /// When null, uses token [TilawaSheetHandleTokens.marginTop] and
  /// [TilawaSheetHandleTokens.marginBottom]. When set, replaces that default
  /// entirely.
  final EdgeInsetsGeometry? margin;
  final Color? color;

  /// When true and [margin] is null, top inset is zero so a parent
  /// ([Positioned], padding, etc.) can own vertical placement; bottom still
  /// uses the token.
  final bool omitTopMargin;

  /// When true, downward drags on the expanded handle region dismiss the sheet.
  final bool enableDragToDismiss;

  /// Called instead of [Navigator.maybePop] when drag-to-dismiss fires.
  final VoidCallback? onDismiss;

  /// Screen reader label for the dismiss handle.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.sheetHandle;
    if (!showHandle) {
      return const SizedBox.shrink();
    }

    final EdgeInsetsGeometry resolvedMargin =
        margin ??
        EdgeInsets.only(
          top: omitTopMargin ? 0 : componentTokens.marginTop,
          bottom: componentTokens.marginBottom,
        );

    final Widget pill = Container(
      width: width ?? componentTokens.width,
      height: height ?? componentTokens.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(componentTokens.cornerRadius),
        color:
            color ??
            theme.colorScheme.onSurface.withValues(
              alpha: componentTokens.colorOpacity,
            ),
      ),
    );

    final Widget handleBody = Padding(
      padding: resolvedMargin,
      child: SizedBox(
        width: double.infinity,
        height: kTilawaMinInteractiveDimension,
        child: Center(child: pill),
      ),
    );

    if (!enableDragToDismiss) {
      return handleBody;
    }

    // Bare detector: expanded hit strip for drag-to-dismiss only; not a visible
    // button surface beyond the pill (see kTilawaMinInteractiveDimension dartdoc).
    return Semantics(
      button: true,
      label: semanticLabel ?? 'Dismiss sheet',
      child: GestureDetector(
        behavior: .opaque,
        onVerticalDragEnd: (DragEndDetails details) =>
            _handleDragEnd(context, details),
        child: handleBody,
      ),
    );
  }

  void _handleDragEnd(BuildContext context, DragEndDetails details) {
    final threshold = Theme.of(context).tokens.playerDismissVelocityThreshold;
    final velocity = details.primaryVelocity;
    if (velocity == null || velocity <= threshold) {
      return;
    }
    if (onDismiss != null) {
      onDismiss!();
    } else {
      Navigator.maybePop(context);
    }
  }
}
