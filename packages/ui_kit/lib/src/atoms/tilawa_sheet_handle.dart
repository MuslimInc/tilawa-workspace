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

  /// Optional margin around the drag pill. When null, no inset is applied;
  /// parent layout owns spacing around the handle.
  final EdgeInsetsGeometry? margin;
  final Color? color;

  /// No longer applies default insets; kept for call-site compatibility.
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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.sheetHandle;
    if (!showHandle) {
      return const SizedBox.shrink();
    }

    final double pillHeight = height ?? componentTokens.height;
    final double pillWidth = width ?? componentTokens.width;
    final BorderRadius borderRadius = BorderRadius.circular(
      designTokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: pillHeight,
      ),
    );

    final Widget pill = Container(
      width: width ?? componentTokens.width,
      height: pillHeight,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color:
            color ??
            theme.colorScheme.onSurface.withValues(
              alpha: componentTokens.colorOpacity,
            ),
      ),
    );

    final Widget handleBody = SizedBox(
      width: double.infinity,
      height: kTilawaMinInteractiveDimension,
      child: Center(child: pill),
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
