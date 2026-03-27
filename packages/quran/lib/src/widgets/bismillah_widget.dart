import 'package:flutter/material.dart';

import '../helpers/app_logger.dart';

class BismillahWidget extends StatelessWidget {
  const BismillahWidget({
    super.key,
    required this.fontSize,
    required this.pageNumber,
    this.color,
    this.fontFamily,
  });

  final double fontSize;
  final int pageNumber;
  final Color? color;
  final String? fontFamily;

  static const double _lineHeight = 2.30;
  static const double _calligraphyFontScale = 0.8;

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();

    // Strategy for Bismillah rendering:
    // 1. Page 1: Bismillah is part of the Ayahs (Ayah 1),
    //    so it uses the page-specific font with the 0xFC41 range.
    // 2. Other Pages: The page-specific font typically has a special
    //    calligraphic Bismillah glyph at 0x0008 (User verified).
    //    Fallback to QCF_BSML if not using page font.

    final String bismillahText;
    final String bismillahFont;
    final double effectiveFontSize;

    if (pageNumber == 1) {
      bismillahText = '\uFC41\uFC42\uFC43\uFC44';
      bismillahFont = fontFamily ?? 'QCF_P001';
      effectiveFontSize = fontSize;
    } else {
      // For Page 2+, 0xFC41 is the first word of the first Ayah (e.g. Alif-Lam-Mim).
      // The actual Bismillah is at 0x0008 in the page font.
      // bismillahText = '\u0008';
      bismillahText = '齃𧻓𥳐龎';

      bismillahFont = 'QCF_BSML';
      effectiveFontSize = fontSize * _calligraphyFontScale;
    }

    final result = Text(
      bismillahText,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: bismillahFont,
        package: 'quran',
        fontSize: effectiveFontSize,
        color: color,
        height: _lineHeight,
      ),
    );

    final Duration renderDuration = DateTime.now().difference(renderStartTime);
    if (renderDuration.inMilliseconds > 4) {
      logger.d(
        '[PageContent] BismillahWidget build took ${renderDuration.inMilliseconds}ms',
      );
    }
    return result;
  }
}
