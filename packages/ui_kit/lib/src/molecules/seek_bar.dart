import 'dart:math';

import 'package:flutter/material.dart';

import '../atoms/hidden_thumb_shape.dart';
import '../foundation/component_tokens.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.bufferedPosition = .zero,
    this.activeColor,
    this.inactiveColor,
    this.bufferedColor,
    this.thumbColor,
    this.onChanged,
    this.onChangeEnd,
  });
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? bufferedColor;
  final Color? thumbColor;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = Theme.of(context).componentTokens.seekBar;

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: tokens.trackHeight,
      thumbShape: widget.duration.inMilliseconds > 0
          ? RoundSliderThumbShape(enabledThumbRadius: tokens.thumbRadius)
          : HiddenThumbComponentShape(),
      overlayShape: widget.duration.inMilliseconds > 0
          ? const RoundSliderOverlayShape()
          : SliderComponentShape.noOverlay,
      trackShape: const RoundedRectSliderTrackShape(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // fix: Accessibility — touch strip height from tokens (≥48dp)
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.seekBar;
    final baseColor = theme.colorScheme.onPrimary;
    final activeColor = widget.activeColor ?? baseColor;
    final inactiveColor =
        widget.inactiveColor ??
        baseColor.withValues(alpha: tokens.inactiveTrackOpacity);
    final bufferedColor =
        widget.bufferedColor ??
        baseColor.withValues(alpha: tokens.bufferedTrackOpacity);
    final thumbColor = widget.thumbColor ?? activeColor;
    final double value = min(
      _dragValue ?? widget.position.inMilliseconds.toDouble(),
      widget.duration.inMilliseconds.toDouble(),
    );
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }

    return Column(
      children: [
        // Progress bar
        Container(
          height: tokens.touchExtent,
          margin: EdgeInsets.symmetric(horizontal: tokens.horizontalMargin),
          child: Stack(
            alignment: .center, // Center the sliders vertically
            clipBehavior: .none,
            children: [
              // Buffered progress background
              SliderTheme(
                data: _sliderThemeData.copyWith(
                  thumbShape: HiddenThumbComponentShape(),
                  activeTrackColor: bufferedColor,
                  inactiveTrackColor: inactiveColor,
                ),
                child: ExcludeSemantics(
                  child: Slider(
                    max: widget.duration.inMilliseconds.toDouble(),
                    value: min(
                      widget.bufferedPosition.inMilliseconds.toDouble(),
                      widget.duration.inMilliseconds.toDouble(),
                    ),
                    onChanged: (value) {},
                  ),
                ),
              ),
              // Current progress
              SliderTheme(
                data: _sliderThemeData.copyWith(
                  inactiveTrackColor: Colors.transparent,
                  activeTrackColor: activeColor,
                  thumbColor: thumbColor,
                ),
                child: Slider(
                  max: widget.duration.inMilliseconds.toDouble(),
                  value: value,
                  onChanged: widget.duration.inMilliseconds > 0
                      ? (value) {
                          if (!_dragging) {
                            _dragging = true;
                          }
                          setState(() {
                            _dragValue = value;
                          });
                          if (widget.onChanged != null) {
                            widget.onChanged!(
                              Duration(milliseconds: value.round()),
                            );
                          }
                        }
                      : null,
                  onChangeEnd: (value) {
                    if (widget.onChangeEnd != null) {
                      widget.onChangeEnd!(
                        Duration(milliseconds: value.round()),
                      );
                    }
                    _dragging = false;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
