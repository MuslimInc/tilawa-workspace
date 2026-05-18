import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Carousel indicator. The active dot is a 22px-wide pill, inactive dots are
/// 6px circles. Mirrors `.tw-dots`.
class TilawaDots extends StatelessWidget {
  const TilawaDots({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: TilawaMotion.base,
            curve: TilawaMotion.standard,
            width: i == activeIndex ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? c.brand
                  : const Color(0x2E0F172A),
              borderRadius: TilawaRadii.brPill,
            ),
          ),
        ],
      ],
    );
  }
}
