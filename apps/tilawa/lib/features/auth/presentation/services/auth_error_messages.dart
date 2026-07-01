import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/entities/auth_error_key.dart';

/// Resolves [AuthState.error] message keys to localized user-visible copy.
String localizedAuthBlocErrorMessage(
  String message,
  AppLocalizations l10n,
) {
  return switch (message) {
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
    '' => l10n.deleteAccountFailed,
    _ => message,
  };
}
