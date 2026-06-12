import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/datasources/google_sign_in_prepare_data_source.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa_core/constants/app_strings.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGoogleSignIn mockGoogleSignIn;
  late AndroidSignInPlatformPolicy platformPolicy;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    platformPolicy = AndroidSignInPlatformPolicy.test(
      skipAutomaticSignIn: false,
    );
    when(
      () => mockGoogleSignIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: AppStrings.googleClientId,
      ),
    ).thenAnswer((_) async {});
    GoogleSignInPrepareDataSourceImpl.resetPrepareStateForTesting();
  });

  tearDown(() {
    platformPolicy.resetForTesting();
  });

  GoogleSignInPrepareDataSourceImpl buildDataSource() {
    return GoogleSignInPrepareDataSourceImpl(
      mockGoogleSignIn,
      platformPolicy,
    );
  }

  group('GoogleSignInPrepareDataSourceImpl', () {
    test('prepare initializes google_sign_in without silent auth', () async {
      await buildDataSource().prepare();

      verify(
        () => mockGoogleSignIn.initialize(
          clientId: any(named: 'clientId'),
          serverClientId: AppStrings.googleClientId,
        ),
      ).called(1);
      verifyNever(() => mockGoogleSignIn.attemptLightweightAuthentication());
    });

    test('initialize runs only once across repeated prepare calls', () async {
      final GoogleSignInPrepareDataSourceImpl dataSource = buildDataSource();

      await dataSource.prepare();
      await dataSource.prepare();
      await dataSource.ensureInitialized();

      // google_sign_in 7.x forbids calling initialize() twice.
      verify(
        () => mockGoogleSignIn.initialize(
          clientId: any(named: 'clientId'),
          serverClientId: AppStrings.googleClientId,
        ),
      ).called(1);
    });

    test('prepare swallows initialization errors', () async {
      when(
        () => mockGoogleSignIn.initialize(
          clientId: any(named: 'clientId'),
          serverClientId: AppStrings.googleClientId,
        ),
      ).thenThrow(Exception('init failed'));

      await expectLater(buildDataSource().prepare(), completes);
    });

    test('failed initialize is retried on the next call', () async {
      when(
        () => mockGoogleSignIn.initialize(
          clientId: any(named: 'clientId'),
          serverClientId: AppStrings.googleClientId,
        ),
      ).thenThrow(Exception('init failed'));
      final GoogleSignInPrepareDataSourceImpl dataSource = buildDataSource();

      await expectLater(dataSource.ensureInitialized(), throwsException);

      when(
        () => mockGoogleSignIn.initialize(
          clientId: any(named: 'clientId'),
          serverClientId: AppStrings.googleClientId,
        ),
      ).thenAnswer((_) async {});

      await expectLater(dataSource.ensureInitialized(), completes);
    });
  });
}
