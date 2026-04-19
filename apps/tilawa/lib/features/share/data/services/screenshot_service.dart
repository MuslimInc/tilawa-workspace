import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:injectable/injectable.dart';

import 'share_file_manager.dart';

/// Captures the current Quran page and composites a branded PNG image.
@lazySingleton
class ScreenshotService {
  ScreenshotService(this._fileManager);

  final ShareFileManager _fileManager;

  /// Captures the widget behind [boundaryKey] and stores it as a raw PNG.
  ///
  /// [targetWidth] / [targetHeight] let callers pin the PNG to an exact pixel
  /// resolution (e.g. 720x1280 for the video pipeline). When provided, the
  /// pixel ratio is derived from the boundary's logical size so FFmpeg can
  /// skip an expensive `-vf scale,crop` pass on every frame.
  Future<String> captureRaw({
    required GlobalKey boundaryKey,
    String fileName = 'share_capture.png',
    double pixelRatio = 2.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final pageImage = await _captureBoundaryImage(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    try {
      final byteData = await pageImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw StateError('Failed to encode image to PNG.');
      }

      final bytes = byteData.buffer.asUint8List();
      return _fileManager.saveShareFile(bytes: bytes, fileName: fileName);
    } finally {
      pageImage.dispose();
    }
  }

  /// Captures the widget behind [boundaryKey], adds a branded bottom strip
  /// with [surahName] and [pageNumber], and saves the result to a temp file.
  ///
  /// Returns the absolute path to the generated PNG file.
  Future<String> captureAndBrand({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    Color brandColor = const Color(0xFF1B5E20),
    double pixelRatio = 2.0,
  }) async {
    final pageImage = await _captureBoundaryImage(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
    );

    try {
      final branded = await _composeBrandedImage(
        pageImage: pageImage,
        surahName: surahName,
        pageNumber: pageNumber,
        appName: appName,
        sharedViaLabel: sharedViaLabel,
        brandColor: brandColor,
        pixelRatio: pixelRatio,
      );

      final byteData = await branded.toByteData(format: ui.ImageByteFormat.png);
      branded.dispose();

      if (byteData == null) {
        throw StateError('Failed to encode image to PNG.');
      }

      final bytes = byteData.buffer.asUint8List();
      return _fileManager.saveShareFile(
        bytes: bytes,
        fileName: 'quran_page_$pageNumber.png',
      );
    } finally {
      pageImage.dispose();
    }
  }

  Future<ui.Image> _captureBoundaryImage({
    required GlobalKey boundaryKey,
    required double pixelRatio,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('RepaintBoundary not found. Page may still be loading.');
    }

    // If the caller asked for an explicit output pixel resolution, derive the
    // pixel ratio from the boundary's actual logical size. This produces the
    // exact PNG dimensions we want without a second downscale pass later.
    double effectivePixelRatio = pixelRatio;
    if ((targetWidth != null || targetHeight != null) && boundary.hasSize) {
      final Size logicalSize = boundary.size;
      if (logicalSize.width > 0 && logicalSize.height > 0) {
        final double widthRatio = targetWidth != null
            ? targetWidth / logicalSize.width
            : double.infinity;
        final double heightRatio = targetHeight != null
            ? targetHeight / logicalSize.height
            : double.infinity;
        // Pick the smaller ratio so neither dimension overshoots the target.
        final double derived = widthRatio < heightRatio
            ? widthRatio
            : heightRatio;
        if (derived.isFinite && derived > 0) {
          effectivePixelRatio = derived;
        }
      }
    }

    try {
      return await boundary.toImage(pixelRatio: effectivePixelRatio);
    } catch (_) {
      return boundary.toImage(pixelRatio: 1.0);
    }
  }

  Future<ui.Image> _composeBrandedImage({
    required ui.Image pageImage,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    required Color brandColor,
    required double pixelRatio,
  }) async {
    final imageWidth = pageImage.width.toDouble();
    final imageHeight = pageImage.height.toDouble();
    final stripHeight = 56.0 * pixelRatio;
    final totalHeight = imageHeight + stripHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imageWidth, totalHeight),
    );

    // Draw page image.
    canvas.drawImage(pageImage, Offset.zero, Paint());

    // Draw branded bottom strip.
    final stripRect = Rect.fromLTWH(0, imageHeight, imageWidth, stripHeight);
    final stripPaint = Paint()..color = brandColor.withValues(alpha: 0.9);
    canvas.drawRect(stripRect, stripPaint);

    // Draw surah name (left-aligned, RTL-friendly).
    final surahStyle = ui.TextStyle(
      color: const Color(0xFFFFFFFF),
      fontSize: 16.0 * pixelRatio,
      fontWeight: FontWeight.bold,
    );
    final surahParagraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(textDirection: ui.TextDirection.rtl),
          )
          ..pushStyle(surahStyle)
          ..addText('$surahName  |  ${_localizePageLabel(pageNumber)}');
    final surahParagraph = surahParagraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: imageWidth - 32.0 * pixelRatio));
    canvas.drawParagraph(
      surahParagraph,
      Offset(
        16.0 * pixelRatio,
        imageHeight + (stripHeight - surahParagraph.height) / 2,
      ),
    );

    // Draw "Shared via Tilawa" (right side).
    final viaStyle = ui.TextStyle(
      color: const Color(0xB3FFFFFF), // 70% white
      fontSize: 12.0 * pixelRatio,
    );
    final viaParagraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textDirection: ui.TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          )
          ..pushStyle(viaStyle)
          ..addText(sharedViaLabel);
    final viaParagraph = viaParagraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: imageWidth - 32.0 * pixelRatio));
    canvas.drawParagraph(
      viaParagraph,
      Offset(
        16.0 * pixelRatio,
        imageHeight + (stripHeight - viaParagraph.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    return picture.toImage(imageWidth.toInt(), totalHeight.toInt());
  }

  String _localizePageLabel(int pageNumber) {
    return '$pageNumber';
  }
}
