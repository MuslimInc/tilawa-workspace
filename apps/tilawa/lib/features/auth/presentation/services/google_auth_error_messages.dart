import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/entities/google_sign_in_failure_key.dart';

/// Maps [GoogleSignInFailureKey] values to localized user-visible copy.
String localizedGoogleSignInFailureMessage(
  String messageKey,
  AppLocalizations l10n,
) {
  return switch (messageKey) {
    GoogleSignInFailureKey.uiUnavailable => l10n.googleSignInFallbackBody,
    GoogleSignInFailureKey.notConfigured => l10n.googleSignInNotConfigured,
    GoogleSignInFailureKey.timeout => l10n.googleSignInTimeout,
    GoogleSignInFailureKey.timeoutUiHidden => l10n.googleSignInTimeoutUiHidden,
    GoogleSignInFailureKey.userMismatch => l10n.googleSignInUserMismatch,
    GoogleSignInFailureKey.offline => l10n.serverActionOfflineMessage,
    GoogleSignInFailureKey.generic => l10n.authErrorGenericMessage,
    _ => l10n.authErrorGenericMessage,
  };
}
