import 'package:flutter/material.dart';

import '../../../core/design_tokens/design_tokens.dart';

/// Atomic component for displaying the current page number.
///
/// This is a simple text widget styled according to design tokens.
class PageIndicatorText extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final double screenWidth;

  const PageIndicatorText({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = screenWidth * AppDimensions.pageNumberTextSizeRatio;

    return Text(
      'Page $pageNumber',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
