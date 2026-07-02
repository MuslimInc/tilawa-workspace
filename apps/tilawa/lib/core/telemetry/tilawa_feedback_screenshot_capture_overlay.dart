import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom chrome shown while the user navigates to a screen for bug-report capture.
class TilawaFeedbackScreenshotCaptureOverlay extends StatelessWidget {
  const TilawaFeedbackScreenshotCaptureOverlay({
    super.key,
    required this.hintText,
    required this.captureLabel,
    required this.cancelLabel,
    required this.onCapture,
    required this.onCancel,
    this.isCapturing = false,
  });

  final String hintText;
  final String captureLabel;
  final String cancelLabel;
  final VoidCallback? onCapture;
  final VoidCallback? onCancel;
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      key: const ValueKey('tilawa_feedback_screenshot_capture_overlay'),
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceSmall,
            children: <Widget>[
              Text(
                hintText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                spacing: tokens.spaceSmall,
                children: <Widget>[
                  Expanded(
                    child: TilawaButton(
                      key: const ValueKey(
                        'tilawa_feedback_screenshot_capture_cancel',
                      ),
                      text: cancelLabel,
                      variant: TilawaButtonVariant.outline,
                      isFullWidth: true,
                      onPressed: isCapturing ? null : onCancel,
                    ),
                  ),
                  Expanded(
                    child: TilawaButton(
                      key: const ValueKey(
                        'tilawa_feedback_screenshot_capture_now',
                      ),
                      text: captureLabel,
                      isFullWidth: true,
                      isLoading: isCapturing,
                      onPressed: isCapturing ? null : onCapture,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Result of the navigate-then-capture overlay flow.
enum TilawaFeedbackScreenshotOverlayResult {
  cancelled,
  captured,
  failed,
}

/// Inserts and manages the navigate-then-capture overlay above the app shell.
abstract final class TilawaFeedbackScreenshotCaptureOverlayController {
  static OverlayEntry? _entry;

  /// Shows the overlay and resolves when capture or cancel completes.
  static Future<TilawaFeedbackScreenshotOverlayResult> show({
    required OverlayState overlay,
    required String hintText,
    required String captureLabel,
    required String cancelLabel,
    required Future<bool> Function() onCaptureRequested,
  }) {
    final Completer<TilawaFeedbackScreenshotOverlayResult> completer =
        Completer<TilawaFeedbackScreenshotOverlayResult>();
    var isCapturing = false;

    void remove() {
      _entry?.remove();
      _entry = null;
    }

    void finish(TilawaFeedbackScreenshotOverlayResult result) {
      if (completer.isCompleted) {
        return;
      }
      remove();
      completer.complete(result);
    }

    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: TilawaFeedbackScreenshotCaptureOverlay(
            hintText: hintText,
            captureLabel: captureLabel,
            cancelLabel: cancelLabel,
            isCapturing: isCapturing,
            onCancel: () =>
                finish(TilawaFeedbackScreenshotOverlayResult.cancelled),
            onCapture: () {
              if (isCapturing) {
                return;
              }
              isCapturing = true;
              _entry?.markNeedsBuild();
              unawaited(() async {
                final bool captured = await onCaptureRequested();
                finish(
                  captured
                      ? TilawaFeedbackScreenshotOverlayResult.captured
                      : TilawaFeedbackScreenshotOverlayResult.failed,
                );
              }());
            },
          ),
        );
      },
    );

    overlay.insert(_entry!);
    return completer.future;
  }

  @visibleForTesting
  static void resetForTesting() {
    _entry?.remove();
    _entry = null;
  }
}
