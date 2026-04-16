import 'package:flutter/material.dart';

import '../../../core/design_tokens/design_tokens.dart';

/// Molecular component for page navigation slider.
///
/// A Slider widget styled according to design tokens for fast page navigation.
class PageSlider extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double screenWidth;

  const PageSlider({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
    this.onChangeEnd,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = screenWidth * AppDimensions.thumbSizeRatio;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.sliderActiveTrack,
        inactiveTrackColor: AppColors.sliderTrack,
        thumbColor: AppColors.sliderThumb,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: thumbSize / 2,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayColor: AppColors.sliderThumb.withValues(alpha: 0.2),
        overlayShape: RoundSliderOverlayShape(overlayRadius: thumbSize),
      ),
      child: Slider(
        value: currentPage.toDouble(),
        min: 1,
        max: totalPages.toDouble(),
        // divisions intentionally omitted — 603 tick marks are invisible at
        // this density and cause expensive CustomPainter repaints on every
        // animation frame when the nav overlay slides in/out.
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
