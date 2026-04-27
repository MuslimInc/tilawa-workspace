import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations_ar.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../l10n/generated/app_localizations.dart';

extension AppLang on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsAr();
}

extension BuildContextThemeX on BuildContext {
  bool get isDarkMode => theme.brightness == Brightness.dark;
}

extension FailureExtensions on Failure {
  String localizedMessage(BuildContext context) {
    final l10n = context.l10n;

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
    };
  }
}
