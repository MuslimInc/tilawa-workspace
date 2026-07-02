import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture_overlay.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';

/// Draft field values preserved across screenshot capture flows.
class TilawaFeedbackScreenshotDraft {
  const TilawaFeedbackScreenshotDraft({
    required this.name,
    required this.email,
    required this.message,
    this.associatedEventId,
  });

  final String name;
  final String email;
  final String message;
  final SentryId? associatedEventId;
}

/// Localized copy for navigate-then-capture overlay chrome.
class TilawaFeedbackScreenshotCaptureCopy {
  const TilawaFeedbackScreenshotCaptureCopy({
    required this.hint,
    required this.capture,
    required this.cancel,
    required this.captureFailed,
  });

  final String hint;
  final String capture;
  final String cancel;
  final String captureFailed;
}

/// Orchestrates instant, deferred, and navigate-then-capture screenshot flows.
abstract final class TilawaFeedbackScreenshotSession {
  /// Captures the visible screen after layout settles (settings / crash entry).
  static Future<SentryAttachment?> captureDeferredEntry() {
    return TilawaFeedbackScreenshotCapture.captureAttachment(
      waitForReady: true,
    );
  }

  /// Pops the feedback form, captures the screen behind it, then reopens the form.
  static Future<void> attachFromCurrentScreen({
    required BuildContext formContext,
    required TilawaFeedbackScreenshotDraft draft,
    required Hub hub,
    required SentryFlutterOptions flutterOptions,
    required TilawaFeedbackScreenshotCaptureCopy captureFailedCopy,
  }) async {
    if (!formContext.mounted) {
      return;
    }

    Navigator.of(formContext).pop();

    final SentryAttachment? screenshot =
        await TilawaFeedbackScreenshotCapture.captureAttachment(
          waitForReady: true,
        );

    await _reopenForm(
      flutterOptions: flutterOptions,
      hub: hub,
      draft: draft,
      screenshot: screenshot,
      captureFailedCopy: captureFailedCopy,
      showCaptureFailedMessage: screenshot == null,
    );
  }

  /// Lets the user navigate freely, then captures on demand from the overlay.
  static Future<void> attachFromAnotherScreen({
    required BuildContext formContext,
    required TilawaFeedbackScreenshotDraft draft,
    required Hub hub,
    required SentryFlutterOptions flutterOptions,
    required TilawaFeedbackScreenshotCaptureCopy overlayCopy,
  }) async {
    if (!formContext.mounted) {
      return;
    }

    final OverlayState? overlay = Overlay.maybeOf(formContext);
    if (overlay == null) {
      await attachFromCurrentScreen(
        formContext: formContext,
        draft: draft,
        hub: hub,
        flutterOptions: flutterOptions,
        captureFailedCopy: TilawaFeedbackScreenshotCaptureCopy(
          hint: overlayCopy.hint,
          capture: overlayCopy.capture,
          cancel: overlayCopy.cancel,
          captureFailed: overlayCopy.captureFailed,
        ),
      );
      return;
    }

    Navigator.of(formContext).pop();
    await TilawaFeedbackScreenshotCapture.waitForScreenReady(frameCount: 1);

    final TilawaFeedbackScreenshotOverlayResult result =
        await TilawaFeedbackScreenshotCaptureOverlayController.show(
          overlay: overlay,
          hintText: overlayCopy.hint,
          captureLabel: overlayCopy.capture,
          cancelLabel: overlayCopy.cancel,
          onCaptureRequested: () async {
            final SentryAttachment? screenshot =
                await TilawaFeedbackScreenshotCapture.captureAttachment(
                  waitForReady: true,
                );
            if (screenshot == null) {
              return false;
            }

            _pendingScreenshot = screenshot;
            return true;
          },
        );

    final SentryAttachment? screenshot =
        result == TilawaFeedbackScreenshotOverlayResult.captured
        ? _takePendingScreenshot()
        : null;

    await _reopenForm(
      flutterOptions: flutterOptions,
      hub: hub,
      draft: draft,
      screenshot: screenshot,
      captureFailedCopy: TilawaFeedbackScreenshotCaptureCopy(
        hint: overlayCopy.hint,
        capture: overlayCopy.capture,
        cancel: overlayCopy.cancel,
        captureFailed: overlayCopy.captureFailed,
      ),
      showCaptureFailedMessage:
          result == TilawaFeedbackScreenshotOverlayResult.failed,
    );
  }

  static SentryAttachment? _pendingScreenshot;

  @visibleForTesting
  static SentryAttachment? takePendingScreenshotForTesting() {
    return _takePendingScreenshot();
  }

  static SentryAttachment? _takePendingScreenshot() {
    final SentryAttachment? screenshot = _pendingScreenshot;
    _pendingScreenshot = null;
    return screenshot;
  }

  static Future<void> _reopenForm({
    required SentryFlutterOptions flutterOptions,
    required Hub hub,
    required TilawaFeedbackScreenshotDraft draft,
    required TilawaFeedbackScreenshotCaptureCopy captureFailedCopy,
    SentryAttachment? screenshot,
    bool showCaptureFailedMessage = false,
  }) async {
    final BuildContext? rootContext = _resolveRootContext(flutterOptions);
    if (rootContext == null || !rootContext.mounted) {
      return;
    }

    if (showCaptureFailedMessage && screenshot == null) {
      _showCaptureFailedSnackBar(rootContext, captureFailedCopy.captureFailed);
    }

    TilawaSentryFeedbackForm.show(
      rootContext,
      associatedEventId: draft.associatedEventId,
      screenshot: screenshot,
      initialName: draft.name,
      initialEmail: draft.email,
      initialMessage: draft.message,
      hub: hub,
      flutterOptions: flutterOptions,
    );
  }

  static void _showCaptureFailedSnackBar(
    BuildContext context,
    String message,
  ) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) {
      return;
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: scheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static BuildContext? _resolveRootContext(SentryFlutterOptions options) {
    final NavigatorState? navigator = options.navigatorKey?.currentState;
    return navigator?.context ?? options.navigatorKey?.currentContext;
  }
}
