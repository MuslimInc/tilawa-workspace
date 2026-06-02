import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/datasources/google_sign_in_prepare_data_source.dart';
import 'package:tilawa/features/auth/data/services/credential_manager_initializer.dart';
import 'package:tilawa_core/constants/app_strings.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockCredentialManagerInitializer extends Mock
    implements CredentialManagerInitializer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGoogleSignIn mockGoogleSignIn;
  late MockCredentialManagerInitializer mockCredentialManagerInitializer;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockCredentialManagerInitializer = MockCredentialManagerInitializer();
    when(() => mockCredentialManagerInitializer.ensureReady())
        .thenAnswer((_) async {});
    GoogleSignInPrepareDataSourceImpl.resetPrepareStateForTesting();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
      null,
    );
  });

  group('GoogleSignInPrepareDataSourceImpl', () {
    test('prepare invokes native channel on Android credential path', () async {
      String? invokedMethod;
      Map<String, String>? invokedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
        (MethodCall call) async {
          invokedMethod = call.method;
          invokedArgs = (call.arguments as Map<Object?, Object?>?)
              ?.cast<String, String>();
          return true;
        },
      );

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: true,
      );

      await dataSource.prepare();

      verify(() => mockCredentialManagerInitializer.ensureReady()).called(1);
      expect(invokedMethod, 'prepare');
      expect(
        invokedArgs,
        <String, String>{'google_client_id': AppStrings.googleClientId},
      );
      verifyNever(() => mockGoogleSignIn.initialize(serverClientId: any(named: 'serverClientId')));
    });

    test('prepare uses google_sign_in when not on Android credential path',
        () async {
      when(
        () => mockGoogleSignIn.initialize(
          serverClientId: AppStrings.googleClientId,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockGoogleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) async => null);

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: false,
        useGoogleSignInPath: true,
      );

      await dataSource.prepare();

      verify(
        () => mockGoogleSignIn.initialize(
          serverClientId: AppStrings.googleClientId,
        ),
      ).called(1);
      verify(() => mockGoogleSignIn.attemptLightweightAuthentication()).called(1);
    });

    test('prepare swallows channel errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
        (MethodCall call) async {
          throw PlatformException(code: 'ERROR');
        },
      );

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: true,
      );

      await expectLater(dataSource.prepare(), completes);
    });

    test('clear invokes native clear on Android credential path', () async {
      String? invokedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
        (MethodCall call) async {
          invokedMethod = call.method;
          return null;
        },
      );

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: true,
      );

      await dataSource.clear();

      expect(invokedMethod, 'clear');
    });

    test('prepare runs native channel only once when called twice', () async {
      var invokeCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
        (MethodCall call) async {
          if (call.method == 'prepare') {
            invokeCount++;
          }
          return true;
        },
      );

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: true,
      );

      await dataSource.prepare();
      await dataSource.prepare();

      expect(invokeCount, 1);
    });

    test('clear swallows channel errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tilawa.app/google_sign_in_prepare'),
        (MethodCall call) async {
          throw PlatformException(code: 'ERROR');
        },
      );

      final GoogleSignInPrepareDataSourceImpl dataSource =
          GoogleSignInPrepareDataSourceImpl.withOptions(
        mockGoogleSignIn,
        mockCredentialManagerInitializer,
        useAndroidCredentialManager: true,
      );

      await expectLater(dataSource.clear(), completes);
    });
  });
}
