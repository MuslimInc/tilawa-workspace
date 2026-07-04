import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/register_with_email_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/auth/domain/gateways/email_password_auth_gateway.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/auth/domain/usecases/register_with_email_use_case.dart';

import '../../helpers/auth_mock_helper.mocks.dart';
import '../../../../support/fake_network_info.dart';

class _FakeEmailPasswordAuthGateway implements EmailPasswordAuthGateway {
  bool verificationSent = false;

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'unused');

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'unused');

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() async {
    verificationSent = true;
  }
}

EmailRegistrationDraft _draft() => const EmailRegistrationDraft(
  email: 'test@example.com',
  password: 'secret1',
  confirmPassword: 'secret1',
  displayName: 'Test User',
  preferredLanguageCode: 'ar',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegisterWithEmailUseCase useCase;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late _FakeEmailPasswordAuthGateway emailGateway;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    emailGateway = _FakeEmailPasswordAuthGateway();
    networkInfo = FakeNetworkInfo();
    useCase = RegisterWithEmailUseCase(
      mockAuthRepository,
      mockUserRepository,
      emailGateway,
      ServerActionGuard(networkInfo),
    );
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  final UserEntity user = UserEntity(
    id: '123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2024),
  );

  test('creates auth then saves complete profile with verification', () async {
    when(
      mockAuthRepository.registerWithEmailPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer((_) async => AuthResult.success(user: user));
    when(
      mockUserRepository.saveCompleteEmailRegistration(
        user: anyNamed('user'),
        draft: anyNamed('draft'),
      ),
    ).thenAnswer((_) async {});

    final RegisterWithEmailResult result = await useCase(draft: _draft());
    await Future<void>.delayed(Duration.zero);

    expect(result, RegisterWithEmailResult.completed(user: user));
    verify(
      mockUserRepository.saveCompleteEmailRegistration(
        user: anyNamed('user'),
        draft: anyNamed('draft'),
      ),
    ).called(1);
    expect(emailGateway.verificationSent, isTrue);
  });

  test('returns authFailed when offline before Firebase call', () async {
    networkInfo.connected = false;

    final RegisterWithEmailResult result = await useCase(draft: _draft());

    expect(
      result,
      isA<RegisterWithEmailAuthFailed>().having(
        (RegisterWithEmailAuthFailed r) => r.message,
        'message',
        ServerActionFailureKey.offline,
      ),
    );
    verifyNever(
      mockAuthRepository.registerWithEmailPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });

  test('returns authFailed when email already registered', () async {
    when(
      mockAuthRepository.registerWithEmailPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer(
      (_) async => const AuthResult.failure(
        message: EmailAuthFailureKey.emailAlreadyInUse,
        code: 'email-already-in-use',
      ),
    );

    final RegisterWithEmailResult result = await useCase(draft: _draft());

    expect(
      result,
      const RegisterWithEmailResult.authFailed(
        message: EmailAuthFailureKey.emailAlreadyInUse,
        code: 'email-already-in-use',
      ),
    );
    verifyNever(
      mockUserRepository.saveCompleteEmailRegistration(
        user: anyNamed('user'),
        draft: anyNamed('draft'),
      ),
    );
  });

  test(
    'returns authFailed when email exists under Google provider',
    () async {
      when(
        mockAuthRepository.registerWithEmailPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer(
        (_) async => const AuthResult.failure(
          message: EmailAuthFailureKey.emailAlreadyInUseWithGoogle,
          code: 'email-already-in-use',
        ),
      );

      final RegisterWithEmailResult result = await useCase(draft: _draft());

      expect(
        result,
        const RegisterWithEmailResult.authFailed(
          message: EmailAuthFailureKey.emailAlreadyInUseWithGoogle,
          code: 'email-already-in-use',
        ),
      );
    },
  );

  test(
    'returns profile persistence failure when firestore write fails',
    () async {
      when(
        mockAuthRepository.registerWithEmailPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => AuthResult.success(user: user));
      when(
        mockUserRepository.saveCompleteEmailRegistration(
          user: anyNamed('user'),
          draft: anyNamed('draft'),
        ),
      ).thenThrow(Exception('firestore'));

      final RegisterWithEmailResult result = await useCase(draft: _draft());

      expect(
        result,
        RegisterWithEmailResult.profilePersistenceFailed(user: user),
      );
    },
  );
}
