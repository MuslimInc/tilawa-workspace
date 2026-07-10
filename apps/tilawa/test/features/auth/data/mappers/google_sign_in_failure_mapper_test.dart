import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/auth/data/mappers/google_sign_in_failure_mapper.dart';
import 'package:tilawa/features/auth/domain/entities/google_sign_in_failure_key.dart';

void main() {
  group('GoogleSignInFailureMapper.messageKeyForException', () {
    test('maps uiUnavailable to fallback body key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForException(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.uiUnavailable,
            description: 'No activity',
          ),
        ),
      ).equals(GoogleSignInFailureKey.uiUnavailable);
    });

    test('maps configuration errors to notConfigured key', () {
      for (final code in [
        GoogleSignInExceptionCode.clientConfigurationError,
        GoogleSignInExceptionCode.providerConfigurationError,
      ]) {
        check(
          GoogleSignInFailureMapper.messageKeyForException(
            GoogleSignInException(
              code: code,
              description: 'Missing SHA-1 fingerprint',
            ),
          ),
        ).equals(GoogleSignInFailureKey.notConfigured);
      }
    });

    test('maps userMismatch to userMismatch key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForException(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.userMismatch,
            description: 'Wrong account',
          ),
        ),
      ).equals(GoogleSignInFailureKey.userMismatch);
    });

    test('maps unknownError to generic key even with raw description', () {
      check(
        GoogleSignInFailureMapper.messageKeyForException(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
            description: '[16] Cancelled by user.',
          ),
        ),
      ).equals(GoogleSignInFailureKey.generic);
    });

    test('maps network description to offline key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForException(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
            description: 'A network error (such as timeout) has occurred.',
          ),
        ),
      ).equals(GoogleSignInFailureKey.offline);
    });
  });

  group('GoogleSignInFailureMapper.messageKeyForPlatformException', () {
    test('maps network platform errors to offline key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForPlatformException(
          PlatformException(
            code: 'sign_in_failed',
            message: 'Network error: connection timed out',
          ),
        ),
      ).equals(GoogleSignInFailureKey.offline);
    });

    test('maps other platform errors to generic key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForPlatformException(
          PlatformException(
            code: 'sign_in_failed',
            message: 'com.google.android.gms.common.api.ApiException: 10',
          ),
        ),
      ).equals(GoogleSignInFailureKey.generic);
    });
  });

  group('GoogleSignInFailureMapper.messageKeyForTimeout', () {
    test('maps standard timeout to timeout key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForTimeout(
          uiHiddenProbeFailed: false,
        ),
      ).equals(GoogleSignInFailureKey.timeout);
    });

    test('maps hidden UI probe timeout to timeoutUiHidden key', () {
      check(
        GoogleSignInFailureMapper.messageKeyForTimeout(
          uiHiddenProbeFailed: true,
        ),
      ).equals(GoogleSignInFailureKey.timeoutUiHidden);
    });
  });
}
