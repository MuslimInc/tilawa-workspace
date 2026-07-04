import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/google_sign_in_failure_key.dart';
import 'package:tilawa/features/auth/presentation/services/auth_error_messages.dart';
import 'package:tilawa/features/auth/presentation/services/google_auth_error_messages.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations enL10n;
  late AppLocalizations arL10n;

  setUpAll(() async {
    enL10n = await AppLocalizations.delegate.load(const Locale('en'));
    arL10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  group('localizedGoogleSignInFailureMessage', () {
    test('maps every Google sign-in failure key to localized copy', () {
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.uiUnavailable,
          enL10n,
        ),
        enL10n.googleSignInFallbackBody,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.notConfigured,
          enL10n,
        ),
        enL10n.googleSignInNotConfigured,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.timeout,
          enL10n,
        ),
        enL10n.googleSignInTimeout,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.timeoutUiHidden,
          enL10n,
        ),
        enL10n.googleSignInTimeoutUiHidden,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.userMismatch,
          enL10n,
        ),
        enL10n.googleSignInUserMismatch,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.offline,
          arL10n,
        ),
        arL10n.serverActionOfflineMessage,
      );
      expect(
        localizedGoogleSignInFailureMessage(
          GoogleSignInFailureKey.generic,
          enL10n,
        ),
        enL10n.authErrorGenericMessage,
      );
    });

    test('never displays raw platform exception text', () {
      const rawMessages = <String>[
        '[16] Cancelled by user.',
        '[16] Account reauth failed.',
        'Missing SHA-1 fingerprint',
        'No activity',
      ];

      for (final raw in rawMessages) {
        final resolved = localizedAuthBlocErrorMessage(raw, enL10n);
        expect(resolved, enL10n.authErrorGenericMessage, reason: raw);
        expect(resolved, isNot(contains('[16]')));
      }
    });
  });
}
