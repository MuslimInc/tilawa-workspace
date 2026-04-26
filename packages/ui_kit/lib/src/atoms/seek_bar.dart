import 'dart:math';

import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';
import 'hidden_thumb_shape.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    this.bufferedPosition = .zero,
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
    final tokens = Theme.of(context).tokens;

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: tokens.spaceSmall,
      thumbShape: widget.duration.inMilliseconds > 0
          ? RoundSliderThumbShape(enabledThumbRadius: tokens.radiusMedium)
          : HiddenThumbComponentShape(),
      overlayShape: widget.duration.inMilliseconds > 0
          ? const RoundSliderOverlayShape()
          : SliderComponentShape.noOverlay,
      trackShape: const RoundedRectSliderTrackShape(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
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
          height:
              tokens.spaceExtraLarge *
              1.25, // Increased height for better touch target
          margin: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          child: Stack(
            alignment: .center, // Center the sliders vertically
            clipBehavior: .none,
            children: [
              // Buffered progress background
              SliderTheme(
                data: _sliderThemeData.copyWith(
                  thumbShape: HiddenThumbComponentShape(),
                  activeTrackColor: Colors.white.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                  inactiveTrackColor: Colors.white.withValues(
                    alpha: tokens.opacitySubtle,
                  ),
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
