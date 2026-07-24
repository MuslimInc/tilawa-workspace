import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';
import 'package:tilawa/core/telemetry/report_bug_feature_flags.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_hub.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_session.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_feedback_form.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';

/// Presents [TilawaSentryFeedbackForm] and wires Tilawa-specific feedback policy.
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

    final SentryEvent enriched = SessionDiagnosticsHub.enrichEvent(filtered);

    if (shouldPromptFeedbackForEvent(enriched)) {
      // coverage:ignore-start
      await _presentFeedbackForEvent(enriched);
      // coverage:ignore-end
    }

    return enriched;
  }

  /// Opens the Sentry feedback form from settings or other user actions.
  static Future<void> showManualReportBugForm() async {
    if (!isReportBugEnabled() || !Sentry.isEnabled) {
      return;
    }

    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    applyLocalizedLabels(context.l10n);
    final SentryAttachment? screenshot =
        await TilawaFeedbackScreenshotSession.captureDeferredEntry();
    if (!context.mounted) {
      return;
    }

    TilawaSentryFeedbackForm.show(
      context,
      screenshot: screenshot,
      flutterOptions: _flutterOptions,
    );
  }

  /// Whether to auto-prompt after an event is accepted for upload.
  ///
  /// Production-only fatal crashes on physical devices — avoids nagging on
  /// recoverable errors, dev builds, emulators, and Sentry verify events.
  @visibleForTesting
  static bool shouldPromptFeedbackForEvent(SentryEvent event) {
    if (!isReportBugEnabled() || !kReleaseMode || kIsWeb) {
      return false;
    }

    return shouldPromptFeedbackForEventInRelease(event);
  }

  /// Release-only fatal-crash prompt policy (testable without [kReleaseMode]).
  @visibleForTesting
  static bool shouldPromptFeedbackForEventInRelease(SentryEvent event) {
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

  @visibleForTesting
  static Future<void> presentFeedbackForEventForTesting(SentryEvent event) =>
      _presentFeedbackForEvent(event);

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
        await TilawaFeedbackScreenshotSession.captureDeferredEntry();
    if (!context.mounted) {
      return;
    }

    TilawaSentryFeedbackForm.show(
      context,
      associatedEventId: event.eventId,
      screenshot: screenshot,
      flutterOptions: _flutterOptions,
    );
  }
}
