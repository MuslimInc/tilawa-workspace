import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}

void main() {
  late MockDeviceInfoPlugin mockDeviceInfoPlugin;
  late MockAndroidDeviceInfo mockAndroidDeviceInfo;

  setUp(() {
    mockDeviceInfoPlugin = MockDeviceInfoPlugin();
    mockAndroidDeviceInfo = MockAndroidDeviceInfo();
    when(
      () => mockDeviceInfoPlugin.androidInfo,
    ).thenAnswer((_) async => mockAndroidDeviceInfo);
  });

  AndroidSignInPlatformPolicy buildAndroidPolicy() {
    return AndroidSignInPlatformPolicy.forPlatform(
      deviceInfoPlugin: mockDeviceInfoPlugin,
      isAndroid: true,
    );
  }

  void stubOem({required String manufacturer, required String brand}) {
    when(() => mockAndroidDeviceInfo.manufacturer).thenReturn(manufacturer);
    when(() => mockAndroidDeviceInfo.brand).thenReturn(brand);
  }

  group('AndroidSignInPlatformPolicy', () {
    test('warmUp enables skipAutomaticSignIn on Transsion OEM', () async {
      stubOem(manufacturer: 'INFINIX', brand: 'Infinix');
      final AndroidSignInPlatformPolicy policy = buildAndroidPolicy();

      await policy.warmUp();

      expect(policy.skipAutomaticSignIn, isTrue);
      expect(policy.isWarmUpComplete, isTrue);
    });

    test('warmUp keeps automatic sign-in for non-Transsion OEM', () async {
      stubOem(manufacturer: 'Google', brand: 'pixel');
      final AndroidSignInPlatformPolicy policy = buildAndroidPolicy();

      await policy.warmUp();

      expect(policy.skipAutomaticSignIn, isFalse);
      expect(policy.isWarmUpComplete, isTrue);
    });

    test('warmUp loads device info only once across concurrent calls',
        () async {
      stubOem(manufacturer: 'TECNO MOBILE LIMITED', brand: 'TECNO');
      final AndroidSignInPlatformPolicy policy = buildAndroidPolicy();

      await Future.wait(<Future<void>>[policy.warmUp(), policy.warmUp()]);
      await policy.warmUp();

      verify(() => mockDeviceInfoPlugin.androidInfo).called(1);
      expect(policy.skipAutomaticSignIn, isTrue);
    });

    test('warmUp swallows device info errors and completes', () async {
      when(
        () => mockDeviceInfoPlugin.androidInfo,
      ).thenThrow(Exception('device info unavailable'));
      final AndroidSignInPlatformPolicy policy = buildAndroidPolicy();

      await expectLater(policy.warmUp(), completes);

      expect(policy.skipAutomaticSignIn, isFalse);
      expect(policy.isWarmUpComplete, isTrue);
    });

    test('warmUp is a no-op off Android', () async {
      final AndroidSignInPlatformPolicy policy =
          AndroidSignInPlatformPolicy.forPlatform(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        isAndroid: false,
      );

      await policy.warmUp();

      verifyNever(() => mockDeviceInfoPlugin.androidInfo);
      expect(policy.skipAutomaticSignIn, isFalse);
      expect(policy.isWarmUpComplete, isTrue);
    });

    test('default constructor warms up using the host platform', () async {
      // On the test host (not Android) this takes the early-exit path.
      final AndroidSignInPlatformPolicy policy = AndroidSignInPlatformPolicy(
        deviceInfoPlugin: mockDeviceInfoPlugin,
      );

      await policy.warmUp();

      expect(policy.isWarmUpComplete, isTrue);
    });

    test('resetForTesting clears warm-up state', () async {
      stubOem(manufacturer: 'itel', brand: 'itel');
      final AndroidSignInPlatformPolicy policy = buildAndroidPolicy();
      await policy.warmUp();
      expect(policy.skipAutomaticSignIn, isTrue);

      policy.resetForTesting();

      expect(policy.skipAutomaticSignIn, isFalse);
      expect(policy.isWarmUpComplete, isFalse);
    });
  });
}
