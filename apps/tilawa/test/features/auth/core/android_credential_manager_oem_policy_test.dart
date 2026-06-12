import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/core/android_credential_manager_oem_policy.dart';

void main() {
  group('AndroidCredentialManagerOemPolicy', () {
    test('skips automatic sign-in for Infinix', () {
      expect(
        AndroidCredentialManagerOemPolicy.shouldSkipAutomaticSignIn(
          manufacturer: 'INFINIX',
          brand: 'Infinix',
        ),
        isTrue,
      );
    });

    test('skips automatic sign-in for Tecno and Itel brands', () {
      expect(
        AndroidCredentialManagerOemPolicy.shouldSkipAutomaticSignIn(
          manufacturer: 'TECNO MOBILE LIMITED',
          brand: 'TECNO',
        ),
        isTrue,
      );
      expect(
        AndroidCredentialManagerOemPolicy.shouldSkipAutomaticSignIn(
          manufacturer: 'ITEL',
          brand: 'itel',
        ),
        isTrue,
      );
    });

    test('allows automatic sign-in for Pixel', () {
      expect(
        AndroidCredentialManagerOemPolicy.shouldSkipAutomaticSignIn(
          manufacturer: 'Google',
          brand: 'pixel',
        ),
        isFalse,
      );
    });
  });
}
