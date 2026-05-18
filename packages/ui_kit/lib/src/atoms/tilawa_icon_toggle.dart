import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// A boolean icon toggle: shows [activeIcon] over `primaryContainer` when on,
/// [icon] over `surfaceContainerHigh` when off.
///
/// The on-state and off-state surfaces and icons are explicit, so callers
/// pick the iconography (e.g. `notifications_outlined` ↔ `notifications`)
/// rather than relying on a single icon with a tint change.
class TilawaIconToggle extends StatelessWidget {
  const TilawaIconToggle({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.value,
    required this.onChanged,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.activeIconColor,
    this.inactiveIconColor,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? iconSize;
  final double? padding;
  final double? borderRadius;
  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.iconToggle;
    final designTokens = theme.tokens;

    final double effectiveRadius = borderRadius ?? tokens.borderRadius;
    final Color background = value
        ? (activeBackgroundColor ?? tokens.activeBackgroundColor)
        : (inactiveBackgroundColor ?? tokens.inactiveBackgroundColor);
    final Color iconColor = value
        ? (activeIconColor ?? colorScheme.onPrimaryContainer)
        : (inactiveIconColor ?? colorScheme.onSurfaceVariant);

    return Semantics(
      button: true,
      toggled: value,
      label: semanticLabel,
      child: ConstrainedBox(
        // fix: Accessibility — enforce Tilawa hit target (44 dp).
        constraints: BoxConstraints(
          minWidth: designTokens.minInteractiveDimension,
          minHeight: designTokens.minInteractiveDimension,
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(padding ?? tokens.padding),
                child: Icon(
                  value ? activeIcon : icon,
                  size: iconSize ?? tokens.iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
