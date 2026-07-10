import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/auth/domain/services/auth_invalidation_classifier.dart';

void main() {
  const classifier = AuthInvalidationClassifier();

  group('AuthInvalidationClassifier', () {
    group('definitive codes', () {
      const cases = <String, DefinitiveAuthEndReason>{
        'user-disabled': DefinitiveAuthEndReason.accountDisabled,
        'user-not-found': DefinitiveAuthEndReason.accountDeleted,
        'user-token-expired': DefinitiveAuthEndReason.expiredOrRevoked,
        'user-token-revoked': DefinitiveAuthEndReason.expiredOrRevoked,
        'invalid-user-token': DefinitiveAuthEndReason.expiredOrRevoked,
        'requires-recent-login': DefinitiveAuthEndReason.reauthRequired,
      };

      cases.forEach((code, expectedReason) {
        test('$code → definitive ($expectedReason)', () {
          final result = classifier.classifyAuthError(code: code);
          check(result.isDefinitive).isTrue();
          check(result.reason).equals(expectedReason);
        });
      });

      test('is case-insensitive', () {
        final result = classifier.classifyAuthError(code: 'USER-DISABLED');
        check(result.isDefinitive).isTrue();
        check(result.reason).equals(DefinitiveAuthEndReason.accountDisabled);
      });
    });

    group('transient codes', () {
      for (final code in const <String>[
        'network-request-failed',
        'internal-error',
        'too-many-requests',
        'unknown',
        'timeout',
        '',
        'some-brand-new-code',
      ]) {
        test('"$code" → transient (fail-safe: keep user)', () {
          final result = classifier.classifyAuthError(code: code);
          check(result.isTransient).isTrue();
          check(result.reason).isNull();
        });
      }
    });

    group('App Check attestation', () {
      test('App Check message is always transient even with unknown code', () {
        final result = classifier.classifyAuthError(
          code: 'unknown',
          message: 'Error: App attestation failed.',
        );
        check(result.isTransient).isTrue();
      });

      test('"invalid app check token" message is transient', () {
        final result = classifier.classifyAuthError(
          code: 'failed-precondition',
          message: 'Invalid App Check token.',
        );
        check(result.isTransient).isTrue();
      });
    });
  });
}
