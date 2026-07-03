import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/entities/email_auth_failure_key.dart';

/// Maps [EmailAuthFailureKey] values to localized user-visible copy.
String localizedEmailAuthFailureMessage(
  String messageKey,
  AppLocalizations l10n,
) {
  return switch (messageKey) {
    EmailAuthFailureKey.invalidEmail => l10n.authInvalidEmail,
    EmailAuthFailureKey.weakPassword => l10n.authWeakPassword,
    EmailAuthFailureKey.passwordsDoNotMatch => l10n.authPasswordsDoNotMatch,
    EmailAuthFailureKey.userNotFound => l10n.authUserNotFound,
    EmailAuthFailureKey.wrongPassword => l10n.authWrongPassword,
    EmailAuthFailureKey.emailAlreadyInUse => l10n.authEmailAlreadyInUse,
    EmailAuthFailureKey.emailAlreadyInUseWithGoogle =>
      l10n.authEmailAlreadyInUseWithGoogle,
    EmailAuthFailureKey.accountExistsWithDifferentCredential =>
      l10n.authAccountExistsWithDifferentCredential,
    EmailAuthFailureKey.accountExistsUseEmailPassword =>
      l10n.authAccountExistsUseEmailPassword,
    EmailAuthFailureKey.tooManyRequests => l10n.authTooManyRequests,
    EmailAuthFailureKey.networkError => l10n.serverActionOfflineMessage,
    EmailAuthFailureKey.operationNotAllowed => l10n.authOperationNotAllowed,
    EmailAuthFailureKey.userDisabled => l10n.authUserDisabled,
    EmailAuthFailureKey.invalidCredential => l10n.authInvalidCredential,
    EmailAuthFailureKey.resetEmailSent => l10n.authResetEmailSent,
    EmailAuthFailureKey.generic => l10n.authErrorGenericMessage,
    _ => l10n.authErrorGenericMessage,
  };
}

/// Resolves email auth field validation keys for inline field errors.
String? localizedEmailAuthFieldError(
  String? messageKey,
  AppLocalizations l10n,
) {
  if (messageKey == null) {
    return null;
  }
  return localizedEmailAuthFailureMessage(messageKey, l10n);
}
