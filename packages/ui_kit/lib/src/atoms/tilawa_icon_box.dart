import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';

/// Surface treatment for [TilawaIconBox].
enum TilawaIconBoxVariant {
  /// Hairline border on a neutral fill. Default for catalog and settings.
  outline,

  /// Semantic manuscript tint, no border. Hub navigation only.
  tinted,
}

/// A standardized container for icons with background styling.
///
/// Reads default values from [TilawaIconBoxTokens] for consistent
/// sizing, padding, and corner radius.
class TilawaIconBox extends StatelessWidget {
  const TilawaIconBox({
    super.key,
    required this.icon,
    this.size,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.child,
    this.variant = TilawaIconBoxVariant.outline,
    this.semanticTint = TilawaSemanticTint.ink,
  });

  final IconData icon;
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? borderRadius;
  final double? padding;
  final Widget? child;

  /// [TilawaIconBoxVariant.outline] for catalog/settings;
  /// [TilawaIconBoxVariant.tinted] for hub navigation rows.
  final TilawaIconBoxVariant variant;

  /// Tint role when [variant] is [TilawaIconBoxVariant.tinted].
  final TilawaSemanticTint semanticTint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.iconBox;
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final double effectiveSize = size ?? tokens.iconSize;
    final double effectivePadding = padding ?? tokens.padding;
    final bool isTinted = variant == TilawaIconBoxVariant.tinted;

    final Color resolvedBackground =
        backgroundColor ??
        (isTinted
            ? colorScheme.semanticTintBackground(semanticTint)
            : tokens.backgroundColor);
    final Color resolvedIconColor =
        iconColor ??
        (isTinted
            ? colorScheme.semanticTintForeground(semanticTint)
            : theme.colorScheme.onSurface);

    final BoxDecoration decoration = BoxDecoration(
      color: resolvedBackground,
      borderRadius: BorderRadius.circular(
        borderRadius ??
            designTokens.resolveRadius(
              family: TilawaRadiusFamily.decorative,
            ),
      ),
      border: isTinted
          ? null
          : Border.all(
              color: resolvedIconColor.withValues(
                alpha: tokens.borderOpacity,
              ),
              width: 1.0,
            ),
    );

    return Container(
      padding: EdgeInsets.all(effectivePadding),
      decoration: decoration,
      child:
          child ??
          Icon(
            icon,
            size: effectiveSize,
            color: resolvedIconColor,
          ),
    );
  }
}
