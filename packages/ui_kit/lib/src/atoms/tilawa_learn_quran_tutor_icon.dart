import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../foundation/tilawa_icons.dart';

/// Open Mushaf plus tutor glyph for Learn Quran with Tutor entry points.
///
/// Person and [TilawaIcons.quran] sit side by side so guided hifz reads
/// distinctly from the plain Mushaf on Home Quran Reader tiles.
class TilawaLearnQuranTutorIcon extends StatelessWidget {
  const TilawaLearnQuranTutorIcon({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double gap = size >= 32 ? 3 : 2;
    final double contentWidth = size - gap;
    final double personColumnWidth = contentWidth * 0.43;
    final double mushafColumnWidth = contentWidth * 0.57;
    final double personIconSize = (personColumnWidth * 1.05).clamp(
      size * 0.38,
      size * 0.56,
    );
    final IconData personGlyph = personIconSize >= 16
        ? FluentIcons.person_20_regular
        : personIconSize >= 11
        ? FluentIcons.person_16_regular
        : FluentIcons.person_12_regular;
    final double mushafSize = (mushafColumnWidth * 1.05).clamp(
      size * 0.48,
      size * 0.72,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: personColumnWidth,
            height: size,
            child: Center(
              child: Icon(
                personGlyph,
                size: personIconSize,
                color: color,
              ),
            ),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: mushafColumnWidth,
            height: size,
            child: Center(
              child: TilawaIcons.quran.svg(
                size: mushafSize,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
