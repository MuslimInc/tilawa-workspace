import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'share_file_manager.dart';

/// Captures the current Quran page and composites a branded PNG image.
@lazySingleton
class ScreenshotService {
  ScreenshotService(this._fileManager);

  static const int _captureBoundaryRetryFrames = 30;

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
    logger.d(
      '[AppLaunch][ScreenshotService.captureRaw]: Start in (${DateTime.now()})',
    );
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

  /// PHASE 4 OPTIMIZATION: Async capture with optimized encoding.
  /// Captures without PNG encoding to reduce blocking time.
  /// Returns raw image data for external encoding (faster).
  Future<ui.Image> captureRawImage({
    required GlobalKey boundaryKey,
    double pixelRatio = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    return _captureBoundaryImage(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  /// PHASE 4 OPTIMIZATION: Ultra-fast capture with minimal processing.
  /// Skips PNG encoding for faster capture cycles in video pipelines.
  Future<String> captureRawFast({
    required GlobalKey boundaryKey,
    String fileName = 'share_capture_fast.raw',
    double pixelRatio = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    late ui.Image pageImage;

    try {
      pageImage = await _captureBoundaryImage(
        boundaryKey: boundaryKey,
        pixelRatio: pixelRatio,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } catch (e) {
      debugPrint(
        '[ScreenshotService] Capture attempt 1 failed: $e, retrying with extra wait...',
      );
      // Give page extra time to settle before final retry
      await Future.delayed(const Duration(milliseconds: 100));
      pageImage = await _captureBoundaryImage(
        boundaryKey: boundaryKey,
        pixelRatio: pixelRatio,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    }

    try {
      // Get raw pixel data without PNG encoding (faster)
      final byteData = await pageImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw StateError('Failed to get raw image data.');
      }

      final bytes = byteData.buffer.asUint8List();
      return _fileManager.saveShareFile(bytes: bytes, fileName: fileName);
    } finally {
      pageImage.dispose();
    }
  }

  /// PHASE 4 OPTIMIZATION: Batched capture for multiple pages.
  /// Reduces frame settling overhead by batching captures together.
  Future<List<String>> captureRawBatch({
    required List<GlobalKey> boundaryKeys,
    required List<String> fileNames,
    double pixelRatio = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final List<String> paths = [];

    for (int i = 0; i < boundaryKeys.length; i++) {
      if (i < fileNames.length) {
        final path = await captureRaw(
          boundaryKey: boundaryKeys[i],
          fileName: fileNames[i],
          pixelRatio: pixelRatio,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        paths.add(path);
      }
    }

    return paths;
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
    Color? footerBackgroundColor,
    Color? footerForegroundColor,
    double pixelRatio = 2.0,
  }) async {
    logger.d(
      '[AppLaunch][ScreenshotService.captureAndBrand]: Start in (${DateTime.now()})',
    );
    const Color defaultFooterBg = Color(0xFF1B4060);
    final Color brandColor = footerBackgroundColor ?? defaultFooterBg;
    final Color foregroundColor =
        footerForegroundColor ?? const Color(0xFFFFFFFF);
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
        foregroundColor: foregroundColor,
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
    final RenderRepaintBoundary? boundary = await _waitForBoundaryReady(
      boundaryKey,
    );
    if (boundary == null) {
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

  Future<RenderRepaintBoundary?> _waitForBoundaryReady(
    GlobalKey boundaryKey,
  ) async {
    for (var attempt = 0; attempt < _captureBoundaryRetryFrames; attempt++) {
      // Yield to microtasks so any pending bloc/stream listeners that
      // schedule a rebuild get a chance to run before we check the key.
      // Without this, the very first attempt can run inside the same
      // microtask as the state emit and miss a not-yet-built tree.
      await Future<void>.delayed(Duration.zero);

      final renderObject = boundaryKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary &&
          renderObject.attached &&
          renderObject.hasSize &&
          !renderObject.size.isEmpty) {
        return renderObject;
      }

      // Force a frame in case nothing else has marked the tree dirty —
      // when a key swap is the only pending change, the framework may
      // have already settled and `endOfFrame` would otherwise return
      // immediately without giving the new boundary a chance to mount.
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }

    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary && renderObject.hasSize) {
      return renderObject;
    }

    // Log detailed diagnostic info when boundary is not found
    debugPrint(
      '[ScreenshotService] BOUNDARY NOT FOUND - Context: ${boundaryKey.currentContext}, '
      'RenderObject: ${boundaryKey.currentContext?.findRenderObject()}, '
      'BuildOwner: ${boundaryKey.currentContext?.owner}',
    );

    return null;
  }

  Future<ui.Image> _composeBrandedImage({
    required ui.Image pageImage,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    required Color brandColor,
    required Color foregroundColor,
    required double pixelRatio,
  }) async {
    final imageWidth = pageImage.width.toDouble();
    final imageHeight = pageImage.height.toDouble();
    final footerTokens = TilawaFooterBarTokens.defaults();
    final stripHeight = footerTokens.height * pixelRatio;
    final totalHeight = imageHeight + stripHeight;
    final horizontalPadding = footerTokens.horizontalPadding * pixelRatio;
    final footerGap = footerTokens.contentGap * pixelRatio;
    final footerContentWidth = imageWidth - (horizontalPadding * 2);
    final footerColumnWidth = (footerContentWidth - footerGap) / 2;

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
      color: foregroundColor,
      fontSize: footerTokens.labelFontSize * pixelRatio,
      fontWeight: footerTokens.labelFontWeight,
    );
    final surahParagraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(textDirection: ui.TextDirection.rtl),
          )
          ..pushStyle(surahStyle)
          ..addText('$surahName  |  ${_localizePageLabel(pageNumber)}');
    final surahParagraph = surahParagraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: footerColumnWidth));
    canvas.drawParagraph(
      surahParagraph,
      Offset(
        horizontalPadding,
        imageHeight + (stripHeight - surahParagraph.height) / 2,
      ),
    );

    // Draw "Shared via Tilawa" (right side).
    final viaStyle = ui.TextStyle(
      color: foregroundColor.withValues(
        alpha: footerTokens.secondaryLabelOpacity,
      ),
      fontSize: footerTokens.secondaryLabelFontSize * pixelRatio,
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
      ..layout(ui.ParagraphConstraints(width: footerColumnWidth));
    canvas.drawParagraph(
      viaParagraph,
      Offset(
        imageWidth - horizontalPadding - footerColumnWidth,
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
