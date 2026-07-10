import 'package:tilawa/core/firebase/app_check_failure.dart';

/// Whether an auth/token failure is a temporary verification hiccup or a
/// confirmed, definitive end of the session.
enum AuthInvalidationVerdict {
  /// Temporary — App Check attestation, token-refresh network/internal errors,
  /// throttling, unknown codes. The user must stay signed in; retry and keep
  /// them on the current screen.
  transient,

  /// Confirmed invalid — revoked/expired token, disabled/deleted account, or a
  /// re-auth requirement. Safe to sign out and route to login with a reason.
  definitive,
}

/// Why a session ended definitively — drives the login-screen explanation.
enum DefinitiveAuthEndReason {
  /// Refresh token was revoked or expired (e.g. remote sign-out, password
  /// change, "sign out all other devices").
  expiredOrRevoked,

  /// The account was disabled by an admin.
  accountDisabled,

  /// The account no longer exists (deleted).
  accountDeleted,

  /// A sensitive operation needs a fresh sign-in.
  reauthRequired,
}

/// Result of classifying an auth/token failure.
class AuthInvalidationAssessment {
  const AuthInvalidationAssessment.transient()
    : verdict = AuthInvalidationVerdict.transient,
      reason = null;

  const AuthInvalidationAssessment.definitive(this.reason)
    : verdict = AuthInvalidationVerdict.definitive;

  final AuthInvalidationVerdict verdict;

  /// Non-null only when [verdict] is [AuthInvalidationVerdict.definitive].
  final DefinitiveAuthEndReason? reason;

  bool get isTransient => verdict == AuthInvalidationVerdict.transient;
  bool get isDefinitive => verdict == AuthInvalidationVerdict.definitive;
}

/// Classifies Firebase auth / token-refresh failures as temporary or
/// definitive so the app never performs a destructive logout on a transient
/// App Check or token-refresh error.
///
/// Fail-safe by design: unknown or ambiguous codes are treated as
/// [AuthInvalidationVerdict.transient] — we would rather keep a possibly-valid
/// user signed in and retry than eject a legitimate session.
class AuthInvalidationClassifier {
  const AuthInvalidationClassifier();

  /// Firebase Auth error codes that confirm the session is no longer valid.
  static const Map<String, DefinitiveAuthEndReason> _definitiveCodes =
      <String, DefinitiveAuthEndReason>{
        'user-disabled': DefinitiveAuthEndReason.accountDisabled,
        'user-not-found': DefinitiveAuthEndReason.accountDeleted,
        'user-token-expired': DefinitiveAuthEndReason.expiredOrRevoked,
        'user-token-revoked': DefinitiveAuthEndReason.expiredOrRevoked,
        'token-expired': DefinitiveAuthEndReason.expiredOrRevoked,
        'invalid-user-token': DefinitiveAuthEndReason.expiredOrRevoked,
        'requires-recent-login': DefinitiveAuthEndReason.reauthRequired,
      };

  /// Classifies a Firebase auth/token failure by its [code] (and optional
  /// [message]). App-Check-attributable failures are always transient.
  AuthInvalidationAssessment classifyAuthError({
    required String code,
    String? message,
  }) {
    final String normalizedCode = code.trim().toLowerCase();

    // App Check attestation failures are never a reason to log out.
    if (isAppCheckCallableFailure(code: normalizedCode, message: message)) {
      return const AuthInvalidationAssessment.transient();
    }

    final DefinitiveAuthEndReason? reason = _definitiveCodes[normalizedCode];
    if (reason != null) {
      return AuthInvalidationAssessment.definitive(reason);
    }

    // network-request-failed, internal-error, too-many-requests, timeout,
    // unknown, and anything else → keep the user, retry.
    return const AuthInvalidationAssessment.transient();
  }
}
