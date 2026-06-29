import 'package:flutter/material.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'firebase/app_check_failure.dart';
import '../l10n/generated/app_localizations.dart';

extension AppLang on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension BuildContextThemeX on BuildContext {
  bool get isDarkMode => theme.brightness == Brightness.dark;

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  /// Warm app canvas (`ThemeData.scaffoldBackgroundColor` in light mode).
  Color get scaffoldCanvasColor => theme.scaffoldBackgroundColor;
}

extension FailureExtensions on Failure {
  /// Whether this failure should surface in toasts or error UI.
  bool get shouldShowToUser => switch (this) {
    UserCancelledFailure() => false,
    PurchaseFailure(reason: PurchaseFailureReason.userCancelled) => false,
    InAppUpdateFailure() => false,
    _ => true,
  };

  /// Localized user-facing text, or [null] when [shouldShowToUser] is false.
  String? localizedMessage(BuildContext context) {
    if (!shouldShowToUser) {
      return null;
    }

    final AppLocalizations l10n = lookupAppLocalizations(
      Localizations.localeOf(context),
    );

    return switch (this) {
      OfflinePlaybackFailure(reason: final reason) => switch (reason) {
        OfflinePlaybackReason.notDownloaded => l10n.offlinePlaybackError,
        OfflinePlaybackReason.fileMissing => l10n.offlineFileMissingError,
        OfflinePlaybackReason.downloadIncomplete =>
          l10n.offlineDownloadIncompleteError,
      },
      NetworkFailure() => l10n.networkError,
      ServerFailure() => l10n.serverError,
      CacheFailure() => l10n.cacheError,
      AudioFailure() => l10n.audioError,
      VideoGenerationFailure(reason: final reason) => switch (reason) {
        VideoGenerationFailureReason.invalidFrameFormat =>
          l10n.reelGenerationFailedInvalidFrame,
        VideoGenerationFailureReason.missingScreenshot =>
          l10n.reelGenerationFailedMissingScreenshot,
        VideoGenerationFailureReason.invalidOutput =>
          l10n.reelGenerationFailedInvalidOutput,
        VideoGenerationFailureReason.encodingFailed =>
          l10n.reelGenerationFailed,
      },
      ValidationFailure() => l10n.validationError,
      PermissionFailure() => l10n.permissionError,
      UnexpectedFailure() => l10n.unexpectedError,
      PersistenceFailure() => l10n.persistenceError,
      UIError() => l10n.uiError,
      UserCancelledFailure() => null,
      NotificationFailure(reason: final reason) => switch (reason) {
        NotificationFailureReason.missingPayload =>
          l10n.errorMissingNotificationPayload,
        NotificationFailureReason.invalidPayload =>
          l10n.errorInvalidNotificationPayload,
      },
      PurchaseFailure(reason: final reason) => switch (reason) {
        PurchaseFailureReason.billingUnavailable =>
          l10n.purchaseBillingUnavailable,
        PurchaseFailureReason.productNotFound => l10n.purchaseProductNotFound,
        PurchaseFailureReason.userCancelled => null,
        PurchaseFailureReason.pending => l10n.purchasePending,
        PurchaseFailureReason.verificationFailed =>
          _localizedPurchaseVerificationFailure(l10n, this as PurchaseFailure),
        PurchaseFailureReason.alreadyOwned => l10n.purchaseAlreadyOwned,
        PurchaseFailureReason.network => l10n.networkError,
      },
      AppReviewFailure(reason: final reason) => switch (reason) {
        AppReviewFailureReason.unavailable => l10n.appReviewUnavailable,
        AppReviewFailureReason.requestFailed => l10n.appReviewRequestFailed,
        AppReviewFailureReason.storeListingFailed =>
          l10n.appReviewStoreListingFailed,
        AppReviewFailureReason.platformUnsupported =>
          l10n.appReviewPlatformUnsupported,
      },
      InAppUpdateFailure() => null,
    };
  }
}

String _localizedPurchaseVerificationFailure(
  AppLocalizations l10n,
  PurchaseFailure failure,
) {
  if (isAppCheckPurchaseErrorMessage(failure.message)) {
    return AppCheckUxMessages.supportPurchase(l10n);
  }
  return l10n.purchaseVerificationFailed;
}
