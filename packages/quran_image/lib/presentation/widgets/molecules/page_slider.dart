import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final thumbRadius = tokens.spaceSmall;
    final overlayRadius = tokens.iconSizeLarge;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: tokens.progressHeight + tokens.borderWidthThin,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(
          alpha: tokens.opacitySubtle,
        ),
        thumbColor: colorScheme.primary,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: thumbRadius,
          elevation: 0,
          pressedElevation: tokens.spaceTiny,
        ),
        overlayColor: colorScheme.primary.withValues(
          alpha: tokens.opacitySubtle,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
      ),
      child: RepaintBoundary(
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
      ),
    );
  }
}
