import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/policies/email_auth_form_policy.dart';

void main() {
  group('EmailAuthFormPolicy', () {
    test('rejects invalid email', () {
      expect(
        EmailAuthFormPolicy.validateEmail('not-an-email'),
        EmailAuthFailureKey.invalidEmail,
      );
    });

    test('accepts valid email', () {
      expect(
        EmailAuthFormPolicy.validateEmail('user@example.com'),
        isNull,
      );
    });

    test('rejects short password', () {
      expect(
        EmailAuthFormPolicy.validatePassword('123'),
        EmailAuthFailureKey.weakPassword,
      );
    });

    test('rejects mismatched confirm password', () {
      expect(
        EmailAuthFormPolicy.validateConfirmPassword(
          password: 'secret1',
          confirmPassword: 'secret2',
        ),
        EmailAuthFailureKey.passwordsDoNotMatch,
      );
    });
  });
}
