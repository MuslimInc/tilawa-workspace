import 'package:flutter/material.dart';

import '../helpers/app_logger.dart';
import '../helpers/quran_text_paint.dart';

class BismillahStyleConfig {
  const BismillahStyleConfig({
    required this.text,
    required this.fontFamily,
    this.package,
    this.fontScale = 1.0,
  });
  final String text;
  final String fontFamily;
  final String? package;
  final double fontScale;

  /// Factory defining the universal rules for rendering Bismillah across all Quran pages.
  static BismillahStyleConfig forPage(int pageNumber) {
    if (pageNumber == 1 || pageNumber == 2) {
      // Pages 1 and 2 mirror each other using the native Page 1 word-by-word characters
      return const BismillahStyleConfig(
        text: '\uFC41\u200A\uFC42\uFC43\uFC44',
        fontFamily: 'QCF_P001',
      );
    } else {
      // Pages 3+ utilize the specialized calligraphic block sequence from the QCF_BSML font
      return const BismillahStyleConfig(
        text: '齃𧻓𥳐龎',
        fontFamily: 'QCF_BSML',
        package: 'quran',
        fontScale: BismillahWidget._calligraphyFontScale,
      );
    }
  }
}

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

  static const double _lineHeight = 1.8;
  static const double _calligraphyFontScale = 0.8;

  @override
  Widget build(BuildContext context) {
    final renderStartTime = DateTime.now();

    final BismillahStyleConfig config = BismillahStyleConfig.forPage(
      pageNumber,
    );

    final result = Text(
      config.text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: config.fontFamily,
        package: config.package,
        fontSize: fontSize * config.fontScale,
        color: color,
        shadows: buildQuranBoldShadows(color!),
        // height: _lineHeight,
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
