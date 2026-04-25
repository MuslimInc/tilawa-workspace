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
  String localizedMessage(BuildContext context) => switch (this) {
    NetworkFailure() => context.l10n.networkError,
    ServerFailure() => context.l10n.serverError,
    CacheFailure() => context.l10n.cacheError,
    AudioFailure() => context.l10n.audioError,
    ValidationFailure() => context.l10n.validationError,
    PermissionFailure() => context.l10n.permissionError,
    UnexpectedFailure() => context.l10n.unexpectedError,
    PersistenceFailure() => context.l10n.persistenceError,
    UIError() => context.l10n.uiError,
    _ => context.l10n.unknownError,
  };
}
