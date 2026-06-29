import 'package:checks/checks.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/firebase/app_check_failure.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

FirebaseFunctionsException _callable({
  required String code,
  String? message,
}) {
  return FirebaseFunctionsException(
    code: code,
    message: message ?? '',
  );
}

void main() {
  group('isAppCheckCallableFailure', () {
    test('detects explicit App Check message', () {
      check(
        isAppCheckCallableFailure(
          code: 'unauthenticated',
          message: 'App Check token is invalid.',
        ),
      ).isTrue();
    });

    test('detects failed-precondition invalid token message', () {
      check(
        isAppCheckCallableFailure(
          code: 'failed-precondition',
          message: 'Invalid App Check token.',
        ),
      ).isTrue();
    });

    test('ignores generic internal errors', () {
      check(
        isAppCheckCallableFailure(
          code: 'internal',
          message: 'boom',
        ),
      ).isFalse();
    });

    test('maps FirebaseFunctionsException via helper', () {
      check(
        isAppCheckCallableFailureFromException(
          _callable(
            code: 'unauthenticated',
            message: 'Missing App Check token',
          ),
        ),
      ).isTrue();
    });
  });

  group('isAppCheckAuthErrorMessage', () {
    test('detects auth sentinel key', () {
      check(isAppCheckAuthErrorMessage(AuthErrorKey.appCheckFailed)).isTrue();
    });

    test('detects raw Firebase App Check copy', () {
      check(
        isAppCheckAuthErrorMessage('App Check token is invalid.'),
      ).isTrue();
    });
  });

  group('isAppCheckPurchaseErrorMessage', () {
    test('detects purchase sentinel key', () {
      check(
        isAppCheckPurchaseErrorMessage(AppCheckFailureKey.purchase),
      ).isTrue();
    });
  });

  group('AppCheckUxMessages', () {
    late AppLocalizations en;

    setUpAll(() {
      en = lookupAppLocalizations(const Locale('en'));
    });

    test('uses debug copy in debug mode', () {
      check(AppCheckUxMessages.showDebugSetupHint).isTrue();
      check(
        AppCheckUxMessages.authSignIn(en),
      ).equals(en.authAppCheckFailedDebug);
      check(
        AppCheckUxMessages.supportPurchase(en),
      ).equals(en.purchaseAppCheckFailedDebug);
      expect(
        AppCheckUxMessages.authSignIn(en),
        isNot(en.authAppCheckFailedRelease),
      );
    });
  });
}
