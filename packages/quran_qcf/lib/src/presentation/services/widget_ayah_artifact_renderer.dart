import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// Renders QCF text into a byte array (PNG) suitable for Android widgets.
class WidgetAyahArtifactRenderer {
  /// Renders the [qcfText] using [fontFamily] to a PNG byte array.
  /// The [width] and [height] define the maximum bounding box.
  /// If the text is larger, it will be scaled down to fit.
  Future<List<int>> renderAyahToPng({
    required String qcfText,
    required String fontFamily,
    required double width,
    required double height,
    required Color textColor,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final TextSpan span = TextSpan(
      text: qcfText,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: height * 0.8, // Initial large size
        color: textColor,
        height: 1.0,
      ),
    );

    final TextPainter painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    painter.layout(maxWidth: width);

    // Scale down if it exceeds the bounds
    if (painter.size.height > height || painter.size.width > width) {
      final double scale = (height / painter.size.height).clamp(0.1, 1.0);
      final double scaleW = (width / painter.size.width).clamp(0.1, 1.0);
      final double finalScale = scale < scaleW ? scale : scaleW;
      
      final TextSpan scaledSpan = TextSpan(
        text: qcfText,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: (height * 0.8) * finalScale,
          color: textColor,
          height: 1.0,
        ),
      );
      
      final TextPainter scaledPainter = TextPainter(
        text: scaledSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      );
      scaledPainter.layout(maxWidth: width);
      
      final double x = (width - scaledPainter.size.width) / 2;
      final double y = (height - scaledPainter.size.height) / 2;
      scaledPainter.paint(canvas, Offset(x, y));
    } else {
      final double x = (width - painter.size.width) / 2;
      final double y = (height - painter.size.height) / 2;
      painter.paint(canvas, Offset(x, y));
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List() ?? <int>[];
  }
}
