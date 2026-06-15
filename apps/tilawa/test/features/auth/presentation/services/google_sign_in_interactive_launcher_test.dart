import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/presentation/services/google_sign_in_interactive_launcher.dart';

import 'google_sign_in_interactive_launcher_test.mocks.dart';

@GenerateMocks([GoogleSignIn])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGoogleSignIn mockGoogleSignIn;
  late AndroidSignInPlatformPolicy platformPolicy;

  GoogleSignInInteractiveLauncher buildLauncher() {
    return GoogleSignInInteractiveLauncher(
      mockGoogleSignIn,
      platformPolicy,
    );
  }

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    platformPolicy = AndroidSignInPlatformPolicy.test(
      skipAutomaticSignIn: false,
    );
    when(mockGoogleSignIn.supportsAuthenticate()).thenReturn(true);
  });

  test('checkReadiness returns ready when authenticate is supported', () async {
    final GoogleSignInLaunchReadiness result = await buildLauncher()
        .checkReadiness();

    expect(result, isA<GoogleSignInLaunchReady>());
  });

  test('checkReadiness returns uiUnavailable when not supported', () async {
    when(mockGoogleSignIn.supportsAuthenticate()).thenReturn(false);

    final GoogleSignInLaunchReadiness result = await buildLauncher()
        .checkReadiness();

    expect(result, isA<GoogleSignInLaunchUiUnavailable>());
  });

  test('checkReadiness returns platformError on PlatformException', () async {
    when(mockGoogleSignIn.supportsAuthenticate()).thenThrow(
      PlatformException(code: 'test', message: 'blocked'),
    );

    final GoogleSignInLaunchReadiness result = await buildLauncher()
        .checkReadiness();

    expect(result, isA<GoogleSignInLaunchPlatformError>());
  });

  test('checkReadiness returns platformError on unknown exceptions', () async {
    when(mockGoogleSignIn.supportsAuthenticate()).thenThrow(Exception('boom'));

    final GoogleSignInLaunchReadiness result = await buildLauncher()
        .checkReadiness();

    expect(result, isA<GoogleSignInLaunchPlatformError>());
  });

  group('SignInUiSettleTiming', () {
    test('settleDelay uses Transsion delay when OEM policy set', () {
      expect(
        SignInUiSettleTiming.settleDelay(skipAutomaticSignIn: true),
        SignInUiSettleTiming.transsionUiSettleDelay,
      );
      expect(
        SignInUiSettleTiming.settleDelay(skipAutomaticSignIn: false),
        SignInUiSettleTiming.defaultUiSettleDelay,
      );
    });
  });
}
