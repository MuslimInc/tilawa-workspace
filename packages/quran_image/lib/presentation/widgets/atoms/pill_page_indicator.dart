import 'package:flutter/material.dart';

import '../../../core/design_tokens/design_tokens.dart';

/// Atomic component for a pill-shaped page indicator.
///
/// Displays the current page number in a rounded pill container.
class PillPageIndicator extends StatelessWidget {
  final int pageNumber;
  final double screenWidth;

  const PillPageIndicator({
    super.key,
    required this.pageNumber,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final fontSize = screenWidth * AppDimensions.pageNumberTextSizeRatio;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenWidth * 0.02;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(100), // Pill shape
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$pageNumber',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
