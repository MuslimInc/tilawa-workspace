import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/data/mappers/firebase_auth_exception_mapper.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('FirebaseAuthExceptionMapper', () {
    test('maps email-already-in-use to google-specific key when hinted', () {
      final key = FirebaseAuthExceptionMapper.mapToFailureKey(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by google account.',
        ),
      );
      expect(key, EmailAuthFailureKey.emailAlreadyInUseWithGoogle);
    });

    test('maps account-exists-with-different-credential for password', () {
      final key = FirebaseAuthExceptionMapper.mapToFailureKey(
        FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'Account exists with password provider.',
        ),
      );
      expect(key, EmailAuthFailureKey.accountExistsUseEmailPassword);
    });

    test('maps too-many-requests', () {
      final key = FirebaseAuthExceptionMapper.mapToFailureKey(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(key, EmailAuthFailureKey.tooManyRequests);
    });
  });
}
