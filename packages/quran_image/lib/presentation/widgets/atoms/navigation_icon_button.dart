import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Atomic component for navigation icon buttons.
///
/// A circular icon button with consistent sizing and styling.
class NavigationIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double screenWidth;

  const NavigationIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final buttonSize = tokens.iconSizeExtraLarge;
    final iconSize = tokens.iconSizeMedium;
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: isEnabled
                ? colorScheme.surfaceContainerLow
                : colorScheme.surfaceContainerHighest.withValues(
                    alpha: tokens.opacityMedium,
                  ),
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: isEnabled
                  ? colorScheme.primary.withValues(alpha: tokens.opacityMedium)
                  : colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isEnabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(
                    alpha: tokens.opacityMedium,
                  ),
          ),
        ),
      ),
    );
  }
}
