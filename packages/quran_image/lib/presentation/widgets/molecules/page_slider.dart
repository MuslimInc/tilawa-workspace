import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Molecular component for page navigation slider.
///
/// A Slider widget styled according to design tokens for fast page navigation.
///
/// Keeps a local value while the thumb is dragged so the thumb tracks the
/// finger even when [currentPage] only updates on a throttled preview path.
class PageSlider extends StatefulWidget {
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
  State<PageSlider> createState() => _PageSliderState();
}

class _PageSliderState extends State<PageSlider> {
  bool _dragging = false;
  double? _dragValue;

  @override
  void didUpdateWidget(PageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.currentPage != widget.currentPage) {
      _dragValue = null;
    }
  }

  double get _sliderValue {
    final raw = _dragging && _dragValue != null
        ? _dragValue!
        : widget.currentPage.toDouble();
    return raw.clamp(1.0, widget.totalPages.toDouble());
  }

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
          value: _sliderValue,
          min: 1,
          max: widget.totalPages.toDouble(),
          // divisions intentionally omitted — 603 tick marks are invisible at
          // this density and cause expensive CustomPainter repaints on every
          // animation frame when the nav overlay slides in/out.
          onChangeStart: (_) {
            setState(() {
              _dragging = true;
              _dragValue = widget.currentPage.toDouble();
            });
          },
          onChanged: (value) {
            setState(() => _dragValue = value);
            widget.onChanged(value);
          },
          onChangeEnd: (value) {
            setState(() {
              _dragging = false;
              _dragValue = null;
            });
            widget.onChangeEnd?.call(value);
          },
        ),
      ),
    );
  }
}
