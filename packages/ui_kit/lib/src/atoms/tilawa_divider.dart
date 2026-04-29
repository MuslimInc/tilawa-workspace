import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A standardized divider with token-driven defaults.
///
/// Wraps [Divider] with a default height of 1.0 and themed color
/// from the color scheme, matching the most common usage across
/// the Tilawa app.
class TilawaDivider extends StatelessWidget {
  /// Creates a themed divider.
  const TilawaDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  });

  /// Height of the divider (total space occupied).
  final double? height;

  /// Thickness of the divider line.
  final double? thickness;

  /// Leading indent.
  final double? indent;

  /// Trailing indent.
  final double? endIndent;

  /// Color override. Defaults to `colorScheme.outlineVariant`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.divider;

    return Divider(
      height: height ?? tokens.height,
      thickness: thickness ?? tokens.thickness,
      indent: indent,
      endIndent: endIndent,
      color:
          color ??
          theme.colorScheme.outlineVariant.withValues(
            alpha: tokens.colorOpacity,
          ),
    );
  }
}
