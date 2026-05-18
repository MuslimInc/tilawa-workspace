import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Linear progress bar (`.tw-progress`). 4px thick by default, gradient fill,
/// optional draggable thumb (matches `.tw-progress--thumb`).
///
/// Uses fractional layout — safe under [IntrinsicColumnWidth] (e.g. alchemist
/// golden cells), unlike a [LayoutBuilder]-based approach.
class TilawaProgressBar extends StatelessWidget {
  const TilawaProgressBar({
    required this.value,
    this.height = 4,
    this.showThumb = false,
    this.trackColor,
    this.fillGradient,
    super.key,
  }) : assert(value >= 0 && value <= 1);

  final double value;
  final double height;
  final bool showThumb;
  final Color? trackColor;
  final Gradient? fillGradient;

  @override
  Widget build(BuildContext context) {
    final gradient = fillGradient ??
        const LinearGradient(
          colors: [TilawaPalette.green500, TilawaPalette.green700],
        );

    return Semantics(
      value: '${(value * 100).round()}%',
      child: SizedBox(
        height: showThumb ? 14 : height,
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Track (full width).
            Align(
              alignment: Alignment.center,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: trackColor ?? const Color(0x0F0F172A),
                  borderRadius: TilawaRadii.brPill,
                ),
              ),
            ),
            // Fill (fractional width).
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: TilawaRadii.brPill,
                  ),
                ),
              ),
            ),
            // Thumb (anchored at value · width).
            if (showThumb)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(7, 0),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2E000000),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: TilawaPalette.green600,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
