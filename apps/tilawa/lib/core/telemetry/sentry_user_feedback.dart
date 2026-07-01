import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';

/// Presents [SentryFeedbackForm] and wires Tilawa-specific feedback policy.
abstract final class SentryUserFeedback {
  static SentryFlutterOptions? _flutterOptions;

  /// Retains [options] so localized labels can be applied at presentation time.
  static void bindFlutterOptions(SentryFlutterOptions options) {
    _flutterOptions = options;
  }

  @visibleForTesting
  static SentryFlutterOptions? get boundFlutterOptions => _flutterOptions;

  @visibleForTesting
  static void resetForTesting() {
    _flutterOptions = null;
  }
  /// Chained [beforeSend]: existing Tilawa filters, then optional feedback UI.
  static Future<SentryEvent?> filterBeforeSend(
    SentryEvent event,
    Hint hint,
  ) async {
    final SentryEvent? filtered = CrashReportingContext.filterBeforeSend(
      event,
      hint,
    );
    if (filtered == null) {
      return null;
    }

    if (shouldPromptFeedbackForEvent(filtered)) {
      await _presentFeedbackForEvent(filtered);
    }

    return filtered;
  }

  /// Opens the Sentry feedback form from settings or other user actions.
  static Future<void> showManualReportBugForm() async {
    if (!Sentry.isEnabled) {
      return;
    }

    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    applyLocalizedLabels(context.l10n);
    final SentryAttachment? screenshot =
        await SentryFlutter.captureScreenshot();
    if (!context.mounted) {
      return;
    }

    SentryFeedbackForm.show(
      context,
      screenshot: screenshot,
    );
  }

  /// Whether to auto-prompt after an event is accepted for upload.
  ///
  /// Production-only fatal crashes on physical devices — avoids nagging on
  /// recoverable errors, dev builds, emulators, and Sentry verify events.
  @visibleForTesting
  static bool shouldPromptFeedbackForEvent(SentryEvent event) {
    if (!kReleaseMode || kIsWeb) {
      return false;
    }

    if (event.tags?[CrashReportingTagKeys.sentryVerify] == 'true') {
      return false;
    }

    if (event.level != SentryLevel.fatal) {
      return false;
    }

    final String? deviceKind = event.tags?[CrashReportingTagKeys.deviceKind];
    if (deviceKind == 'emulator' || deviceKind == 'simulator') {
      return false;
    }

    return true;
  }

  static void applyLocalizedLabels(AppLocalizations l10n) {
    final SentryFlutterOptions? options = _flutterOptions;
    if (options == null) {
      return;
    }

    final feedback = options.feedback;
    feedback.title = l10n.reportBugTitle;
    feedback.formTitle = l10n.reportBugFormTitle;
    feedback.messageLabel = l10n.reportBugMessageLabel;
    feedback.messagePlaceholder = l10n.reportBugMessagePlaceholder;
    feedback.nameLabel = l10n.reportBugNameLabel;
    feedback.namePlaceholder = l10n.reportBugNamePlaceholder;
    feedback.emailLabel = l10n.reportBugEmailLabel;
    feedback.emailPlaceholder = l10n.reportBugEmailPlaceholder;
    feedback.submitButtonLabel = l10n.reportBugSubmitButton;
    feedback.cancelButtonLabel = l10n.reportBugCancelButton;
    feedback.successMessageText = l10n.reportBugSuccessMessage;
    feedback.isRequiredLabel = l10n.reportBugRequiredLabel;
    feedback.validationErrorLabel = l10n.reportBugValidationError;
    feedback.captureScreenshotButtonLabel = l10n.reportBugCaptureScreenshot;
    feedback.removeScreenshotButtonLabel = l10n.reportBugRemoveScreenshot;
    feedback.showBranding = false;
    feedback.useSentryUser = true;
  }

  static Future<void> _presentFeedbackForEvent(SentryEvent event) async {
    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    applyLocalizedLabels(context.l10n);
    final SentryAttachment? screenshot =
        await SentryFlutter.captureScreenshot();
    if (!context.mounted) {
      return;
    }

    SentryFeedbackForm.show(
      context,
      associatedEventId: event.eventId,
      screenshot: screenshot,
    );
  }
}
