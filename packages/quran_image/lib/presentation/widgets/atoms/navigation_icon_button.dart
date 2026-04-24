import 'package:flutter/material.dart';

import '../../../core/design_tokens/design_tokens.dart';

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
    final buttonSize = screenWidth * AppDimensions.iconButtonSizeRatio;
    final iconSize = screenWidth * AppDimensions.iconSizeRatio;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: onPressed != null
                ? AppColors.sliderBackground
                : AppColors.divider,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
