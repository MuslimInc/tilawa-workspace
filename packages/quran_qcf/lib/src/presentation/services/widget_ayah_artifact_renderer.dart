import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// Renders QCF text into a byte array (PNG) suitable for Android widgets.
class WidgetAyahArtifactRenderer {
  /// Line-height multiplier for QCF glyphs. Mushaf glyphs carry tall stacked
  /// diacritics; 1.0 makes wrapped lines collide, the reader uses ~2.0.
  /// 1.7 keeps lines clearly separated while staying widget-compact.
  static const double lineHeightMultiplier = 1.7;

  /// Vertical padding (px) kept above and below the text inside the artifact.
  static const double _verticalPadding = 8;

  /// Renders the [qcfText] using [fontFamily] to a PNG byte array.
  ///
  /// [width] is the artifact width; [height] is the MAXIMUM height. The
  /// output is cropped to the laid-out text height (plus a small padding) so
  /// the widget's `fitCenter` ImageView shows no phantom empty space above or
  /// below the verse (spec 041 compact-UI requirement).
  Future<List<int>> renderAyahToPng({
    required String qcfText,
    required String fontFamily,
    required double width,
    required double height,
    required Color textColor,
  }) async {
    TextPainter buildPainter(double fontSize) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: qcfText,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: textColor,
            height: lineHeightMultiplier,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      );
      painter.layout(maxWidth: width);
      return painter;
    }

    final double maxTextHeight = height - (_verticalPadding * 2);

    // Binary-search the largest font size whose laid-out block fits the
    // bounds. A one-shot proportional rescale under-sizes long verses badly:
    // a smaller font re-wraps into fewer lines, so the needed scale is far
    // gentler than the first layout suggests.
    bool fits(TextPainter p) =>
        p.size.height <= maxTextHeight && p.size.width <= width;
    double lo = 8;
    double hi = 120;
    TextPainter painter = buildPainter(lo);
    while (hi - lo > 1) {
      final double mid = (lo + hi) / 2;
      final TextPainter candidate = buildPainter(mid);
      if (fits(candidate)) {
        lo = mid;
        painter = candidate;
      } else {
        hi = mid;
      }
    }

    // Crop the artifact to the actual text block: no dead vertical space.
    final double outputHeight = (painter.size.height + _verticalPadding * 2)
        .clamp(1.0, height);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, outputHeight),
    );
    painter.paint(
      canvas,
      Offset((width - painter.size.width) / 2, _verticalPadding),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      width.toInt(),
      outputHeight.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData?.buffer.asUint8List() ?? <int>[];
  }
}
