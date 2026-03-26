import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tilawa_core/widgets/hidden_thumb_component_shape.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
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

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 8.0,
      thumbShape: widget.duration.inMilliseconds > 0
          ? const RoundSliderThumbShape(enabledThumbRadius: 12.0)
          : HiddenThumbComponentShape(),
      overlayShape: widget.duration.inMilliseconds > 0
          ? const RoundSliderOverlayShape()
          : SliderComponentShape.noOverlay,
      trackShape: const RoundedRectSliderTrackShape(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          height: 30, // Increased height for better touch target
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center, // Center the sliders vertically
            clipBehavior: Clip.none,
            children: [
              // Buffered progress background
              SliderTheme(
                data: _sliderThemeData.copyWith(
                  thumbShape: HiddenThumbComponentShape(),
                  activeTrackColor: Colors.white.withValues(alpha: 0.3),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
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
                  activeTrackColor: Colors.white,
                  thumbColor: Colors.white,
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
