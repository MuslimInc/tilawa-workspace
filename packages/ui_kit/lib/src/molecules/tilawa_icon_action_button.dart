import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaIconActionButton extends StatelessWidget {
  const TilawaIconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.iconActionButton;
    final effectiveSize = size ?? componentTokens.size;
    final effectiveIconSize = iconSize ?? designTokens.iconSizeMedium;
    final effectiveBorderRadius = BorderRadius.circular(
      componentTokens.borderRadius,
    );

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: isActive
            ? theme.primaryColor.withValues(
                alpha: componentTokens.activeBackgroundOpacity,
              )
            : theme.colorScheme.surface,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          borderRadius: effectiveBorderRadius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: isActive
                    ? theme.primaryColor.withValues(
                        alpha: componentTokens.activeBorderOpacity,
                      )
                    : theme.colorScheme.outlineVariant.withValues(
                        alpha: componentTokens.inactiveBorderOpacity,
                      ),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: effectiveIconSize,
                color: isActive
                    ? theme.primaryColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
