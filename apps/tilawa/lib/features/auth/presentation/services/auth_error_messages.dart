import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/network/network_error_message.dart';
import '../../domain/entities/auth_error_key.dart';

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
    '' => l10n.deleteAccountFailed,
    _ when isNetworkConnectivityErrorMessage(message) =>
      l10n.serverActionOfflineMessage,
    // Unknown values are raw failure/exception text meant for logs, never
    // for users; fall back to generic copy instead of displaying them.
    _ => l10n.authErrorGenericMessage,
  };
}
