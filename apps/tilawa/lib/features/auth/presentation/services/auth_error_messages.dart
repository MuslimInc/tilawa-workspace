import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/network/network_error_message.dart';
import '../../domain/entities/auth_error_key.dart';
import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/entities/google_sign_in_failure_key.dart';
import 'google_auth_error_messages.dart';

/// Resolves [AuthState.error] message keys to localized user-visible copy.
String localizedAuthBlocErrorMessage(
  String message,
  AppLocalizations l10n,
) {
  return switch (message) {
    ServerActionFailureKey.offline => l10n.serverActionOfflineMessage,
    DeleteAccountErrorKey.adminMustUseAdminPanel =>
      l10n.deleteAccountAdminMustUseAdminPanel,
    DeleteAccountErrorKey.walletNotEmpty => l10n.deleteAccountWalletNotEmpty,
    DeleteAccountErrorKey.activeBookingsStudent =>
      l10n.deleteAccountActiveBookingsStudent,
    DeleteAccountErrorKey.activeBookingsTeacher =>
      l10n.deleteAccountActiveBookingsTeacher,
    DeleteAccountErrorKey.alreadyPending => l10n.deleteAccountAlreadyPending,
    DeleteAccountErrorKey.serviceUnavailable =>
      l10n.deleteAccountServiceUnavailable,
    DeleteAccountErrorKey.notSignedIn => l10n.deleteAccountNotSignedIn,
    DeleteAccountErrorKey.failed => l10n.deleteAccountFailed,
    AuthErrorKey.deviceRegistrationFailed => l10n.authDeviceRegistrationFailed,
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
    EmailAuthFailureKey.generic => l10n.authErrorGenericMessage,
    GoogleSignInFailureKey.uiUnavailable ||
    GoogleSignInFailureKey.notConfigured ||
    GoogleSignInFailureKey.timeout ||
    GoogleSignInFailureKey.timeoutUiHidden ||
    GoogleSignInFailureKey.userMismatch ||
    GoogleSignInFailureKey.offline ||
    GoogleSignInFailureKey.generic => localizedGoogleSignInFailureMessage(
      message,
      l10n,
    ),
    '' => l10n.deleteAccountFailed,
    _ when isNetworkConnectivityErrorMessage(message) =>
      l10n.serverActionOfflineMessage,
    // Unknown values are raw failure/exception text meant for logs, never
    // for users; fall back to generic copy instead of displaying them.
    _ => l10n.authErrorGenericMessage,
  };
}
