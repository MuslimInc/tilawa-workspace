import 'package:flutter/material.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

/// A custom RTL slider Atom for Quran navigation.
///
/// This slider is designed to be RTL by mapping x=0 to max and x=width to min.
/// Fits into the Quran Page Navigation bar's slider track and handle.
class MushafSlider extends StatelessWidget {
  const MushafSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.activeColor,
    this.isDark = false,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final Color activeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final PageNavigationBarTheme navTheme = PageNavigationBarTheme.of(context);
    final double trackHeight = navTheme.sliderTrackHeight;
    final double thumbSize = navTheme.sliderThumbSize;
    final double thumbRadius = thumbSize / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double normalizedValue = (value - min) / (max - min);
        // RTL logic: normalizedValue=0 is at the far right
        final double trackWidth = (width - thumbSize).clamp(0.0, width);
        final double thumbLeft = (1 - normalizedValue) * trackWidth;
        final double activeTrackWidth = trackWidth - thumbLeft;

        return GestureDetector(
          onHorizontalDragStart: (details) =>
              onChangeStart(_getValueFromPos(details.localPosition.dx, width)),
          onHorizontalDragUpdate: (details) =>
              onChanged(_getValueFromPos(details.localPosition.dx, width)),
          onHorizontalDragEnd: (details) =>
              onChangeEnd(_getValueFromPos(details.localPosition.dx, width)),
          onTapDown: (details) {
            final double val = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChangeStart(val);
            onChanged(val);
            onChangeEnd(val);
          },
          child: Container(
            height: navTheme.sliderStageHeight,
            width: double.infinity,
            color: Colors.transparent, // Expand hit test area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: thumbRadius),
                  child: Container(
                    height: trackHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Active Track (drawn RTL)
                Positioned(
                  right: thumbRadius,
                  child: Container(
                    height: trackHeight,
                    width: activeTrackWidth,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Handle Thumb
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? scheme.onSurface : scheme.surface,
                        width: navTheme.sliderHandleBorderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getValueFromPos(double x, double width) {
    // RTL logic: x=0 is max, x=width is min
    final double normalized = (1 - (x / width)).clamp(0.0, 1.0);
    return min + (normalized * (max - min));
  }
}
