import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Linear progress bar (`.tw-progress`). 4px thick by default, gradient fill,
/// optional draggable thumb (matches `.tw-progress--thumb`).
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
    return Semantics(
      value: '${(value * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: showThumb ? 14 : height,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: trackColor ?? const Color(0x0F0F172A),
                    borderRadius: TilawaRadii.brPill,
                  ),
                ),
                Container(
                  height: height,
                  width: w * value,
                  decoration: BoxDecoration(
                    gradient: fillGradient ??
                        const LinearGradient(
                          colors: [
                            TilawaPalette.green500,
                            TilawaPalette.green700,
                          ],
                        ),
                    borderRadius: TilawaRadii.brPill,
                  ),
                ),
                if (showThumb)
                  Positioned(
                    left: (w * value) - 7,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
