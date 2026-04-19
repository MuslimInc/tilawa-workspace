import 'package:flutter/material.dart';

import '../atoms/atoms.dart';

/// Molecular component grouping navigation buttons and page indicator.
///
/// Combines previous/next buttons with page number display, and an optional
/// share/reel button shown when [onShare] is provided.
class NavigationButtonGroup extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShare;
  final double screenWidth;

  const NavigationButtonGroup({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.screenWidth,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NavigationIconButton(
          icon: Icons.arrow_back_ios,
          onPressed: onPrevious,
          screenWidth: screenWidth,
        ),
        if (onShare != null)
          NavigationIconButton(
            icon: Icons.video_camera_back_outlined,
            onPressed: onShare,
            screenWidth: screenWidth,
          ),
        PageIndicatorText(
          pageNumber: currentPage,
          totalPages: totalPages,
          screenWidth: screenWidth,
        ),
        NavigationIconButton(
          icon: Icons.arrow_forward_ios,
          onPressed: onNext,
          screenWidth: screenWidth,
        ),
      ],
    );
  }
}
