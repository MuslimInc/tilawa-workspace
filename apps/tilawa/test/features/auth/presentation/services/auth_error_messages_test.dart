import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/presentation/services/auth_error_messages.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('maps delete-account error keys to localized copy', () {
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.adminMustUseAdminPanel,
        l10n,
      ),
      l10n.deleteAccountAdminMustUseAdminPanel,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.walletNotEmpty,
        l10n,
      ),
      l10n.deleteAccountWalletNotEmpty,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.activeBookingsStudent,
        l10n,
      ),
      l10n.deleteAccountActiveBookingsStudent,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.activeBookingsTeacher,
        l10n,
      ),
      l10n.deleteAccountActiveBookingsTeacher,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.alreadyPending,
        l10n,
      ),
      l10n.deleteAccountAlreadyPending,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.serviceUnavailable,
        l10n,
      ),
      l10n.deleteAccountServiceUnavailable,
    );
    expect(
      localizedAuthBlocErrorMessage(
        DeleteAccountErrorKey.notSignedIn,
        l10n,
      ),
      l10n.deleteAccountNotSignedIn,
    );
    expect(
      localizedAuthBlocErrorMessage(DeleteAccountErrorKey.failed, l10n),
      l10n.deleteAccountFailed,
    );
    expect(localizedAuthBlocErrorMessage('', l10n), l10n.deleteAccountFailed);
  });

  test('maps device registration key to localized copy', () {
    expect(
      localizedAuthBlocErrorMessage(
        AuthErrorKey.deviceRegistrationFailed,
        l10n,
      ),
      l10n.authDeviceRegistrationFailed,
    );
  });

  test('never displays unknown error messages; falls back to generic copy', () {
    expect(
      localizedAuthBlocErrorMessage('boom', l10n),
      l10n.authErrorGenericMessage,
    );
  });

  test('never displays raw Firebase/exception text', () {
    const rawMessages = <String>[
      '[firebase_auth/internal-error] An internal error has occurred.',
      'PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10, null, null)',
      "Exception: type 'Null' is not a subtype of type 'String'",
      'FirebaseFunctionsException(internal, INTERNAL, null)',
    ];

    for (final raw in rawMessages) {
      final resolved = localizedAuthBlocErrorMessage(raw, l10n);
      expect(resolved, l10n.authErrorGenericMessage, reason: raw);
      expect(resolved, isNot(contains('Exception')), reason: raw);
    }
  });

  test('maps raw Firebase network copy to offline message', () async {
    final arL10n = await AppLocalizations.delegate.load(const Locale('ar'));

    expect(
      localizedAuthBlocErrorMessage(
        'A network error (such as timeout, interrupted connection or '
        'unreachable host) has occurred.',
        arL10n,
      ),
      arL10n.serverActionOfflineMessage,
    );
  });
}
