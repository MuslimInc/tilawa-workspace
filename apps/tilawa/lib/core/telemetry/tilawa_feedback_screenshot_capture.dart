import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Captures an unmasked PNG of the current app UI for user feedback.
///
/// [SentryFlutter.captureScreenshot] applies session-replay privacy masking
/// (`maskAllText`, `maskAllImages`), which turns bug-report screenshots into
/// black/grey blocks. User-initiated reports need a faithful screen capture.
abstract final class TilawaFeedbackScreenshotCapture {
  static const int _boundaryReadyFrames = 5;
  static const int _defaultReadyFrames = 5;
  static const int _defaultMaxAttempts = 3;
  static const int _minNonBlankPixels = 100;
  static const int _blankChannelThreshold = 10;

  @visibleForTesting
  static int readyFrameCount = _defaultReadyFrames;

  @visibleForTesting
  static int boundaryReadyFrames = _boundaryReadyFrames;

  @visibleForTesting
  static int maxCaptureAttempts = _defaultMaxAttempts;

  @visibleForTesting
  static void resetTestConfiguration() {
    readyFrameCount = _defaultReadyFrames;
    boundaryReadyFrames = _boundaryReadyFrames;
    maxCaptureAttempts = _defaultMaxAttempts;
    attachmentOverride = null;
  }

  @visibleForTesting
  static Future<SentryAttachment?> Function()? attachmentOverride;

  /// Waits for route transition, layout, and [frameCount] painted frames.
  static Future<void> waitForScreenReady({
    int? frameCount,
  }) async {
    final int frames = frameCount ?? readyFrameCount;
    await Future<void>.delayed(Duration.zero);
    for (var frame = 0; frame < frames; frame++) {
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Returns PNG bytes for the current screen, or `null` when capture fails.
  static Future<Uint8List?> capturePngBytes({
    bool waitForReady = false,
    bool rejectBlankCaptures = true,
    int? maxAttempts,
  }) async {
    final int attempts = maxAttempts ?? maxCaptureAttempts;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (waitForReady || attempt > 0) {
        final int readyFrames = attempt == 0 ? 3 : readyFrameCount;
        await waitForScreenReady(frameCount: readyFrames);
      }

      final RenderRepaintBoundary? boundary =
          await _waitForScreenshotBoundary();
      if (boundary == null) {
        continue;
      }

      final Uint8List? bytes = await _renderBoundaryToPng(boundary);
      if (bytes == null) {
        continue;
      }

      if (rejectBlankCaptures && await isMostlyBlank(bytes)) {
        continue;
      }

      return bytes;
    }

    return null;
  }

  /// Returns a [SentryAttachment] suitable for feedback submission.
  static Future<SentryAttachment?> captureAttachment({
    bool waitForReady = false,
    bool rejectBlankCaptures = true,
    int? maxAttempts,
  }) async {
    final Future<SentryAttachment?> Function()? override = attachmentOverride;
    if (override != null) {
      return override();
    }

    final Uint8List? bytes = await capturePngBytes(
      waitForReady: waitForReady,
      rejectBlankCaptures: rejectBlankCaptures,
      maxAttempts: maxAttempts,
    );
    if (bytes == null) {
      return null;
    }

    return SentryAttachment.fromUint8List(
      bytes,
      'screenshot.png',
      contentType: 'image/png',
    );
  }

  /// Whether [pngBytes] is effectively blank (all black / near-black).
  @visibleForTesting
  static Future<bool> isMostlyBlank(Uint8List pngBytes) async {
    final ui.Image image = await decodeImageFromList(pngBytes);
    try {
      final ByteData? rgba = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) {
        return true;
      }

      final Uint8List pixels = rgba.buffer.asUint8List();
      var nonBlankPixels = 0;
      for (var index = 0; index < pixels.length; index += 4) {
        final int red = pixels[index];
        final int green = pixels[index + 1];
        final int blue = pixels[index + 2];
        if (red > _blankChannelThreshold ||
            green > _blankChannelThreshold ||
            blue > _blankChannelThreshold) {
          nonBlankPixels++;
          if (nonBlankPixels >= _minNonBlankPixels) {
            return false;
          }
        }
      }

      return true;
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List?> _renderBoundaryToPng(
    RenderRepaintBoundary boundary,
  ) async {
    final double pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<RenderRepaintBoundary?> _waitForScreenshotBoundary() async {
    final RenderRepaintBoundary? immediate = _findScreenshotBoundary();
    if (immediate != null) {
      return immediate;
    }

    if (boundaryReadyFrames == 0) {
      return _findScreenshotBoundary();
    }

    for (var attempt = 0; attempt < boundaryReadyFrames; attempt++) {
      await Future<void>.delayed(Duration.zero);
      final RenderRepaintBoundary? boundary = _findScreenshotBoundary();
      if (boundary != null) {
        return boundary;
      }

      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }

    return _findScreenshotBoundary();
  }

  static RenderRepaintBoundary? _findScreenshotBoundary() {
    RenderRepaintBoundary? boundary;

    void visit(Element element) {
      if (boundary != null) {
        return;
      }

      if (element.widget is SentryScreenshotWidget) {
        final RenderObject? renderObject = element.findRenderObject();
        if (renderObject is RenderRepaintBoundary &&
            renderObject.attached &&
            renderObject.hasSize &&
            !renderObject.size.isEmpty) {
          boundary = renderObject;
        }
        return;
      }

      element.visitChildren(visit);
    }

    final Element? root = WidgetsBinding.instance.rootElement;
    if (root == null) {
      return null;
    }

    visit(root);
    return boundary;
  }
}
