import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/email_auth_failure_key.dart';

/// Maps [FirebaseAuthException] codes to stable [EmailAuthFailureKey] values.
abstract final class FirebaseAuthExceptionMapper {
  static String mapToFailureKey(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => EmailAuthFailureKey.invalidEmail,
      'weak-password' => EmailAuthFailureKey.weakPassword,
      'user-not-found' => EmailAuthFailureKey.userNotFound,
      'wrong-password' => EmailAuthFailureKey.wrongPassword,
      'invalid-credential' => EmailAuthFailureKey.invalidCredential,
      'email-already-in-use' => _emailAlreadyInUseKey(error),
      'account-exists-with-different-credential' => _accountExistsKey(error),
      'too-many-requests' => EmailAuthFailureKey.tooManyRequests,
      'network-request-failed' => EmailAuthFailureKey.networkError,
      'operation-not-allowed' => EmailAuthFailureKey.operationNotAllowed,
      'user-disabled' => EmailAuthFailureKey.userDisabled,
      _ => EmailAuthFailureKey.generic,
    };
  }

  static String _emailAlreadyInUseKey(FirebaseAuthException error) {
    final String? hint = _providerHint(error);
    if (hint == 'google.com') {
      return EmailAuthFailureKey.emailAlreadyInUseWithGoogle;
    }
    return EmailAuthFailureKey.emailAlreadyInUse;
  }

  static String _accountExistsKey(FirebaseAuthException error) {
    final String? hint = _providerHint(error);
    if (hint == 'password') {
      return EmailAuthFailureKey.accountExistsUseEmailPassword;
    }
    return EmailAuthFailureKey.accountExistsWithDifferentCredential;
  }

  static String? _providerHint(FirebaseAuthException error) {
    final Object? credential = error.credential;
    if (credential is OAuthCredential) {
      return credential.providerId;
    }
    final String message = (error.message ?? '').toLowerCase();
    if (message.contains('google')) {
      return 'google.com';
    }
    if (message.contains('password')) {
      return 'password';
    }
    return null;
  }
}
