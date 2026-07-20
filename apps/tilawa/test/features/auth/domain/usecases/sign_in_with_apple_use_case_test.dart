import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/auth_mock_helper.mocks.dart';
import '../../../../support/fake_network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignInWithAppleUseCase useCase;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    networkInfo = FakeNetworkInfo();
    useCase = SignInWithAppleUseCase(
      mockAuthRepository,
      mockUserRepository,
      ServerActionGuard(networkInfo),
    );
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  final tUser = UserEntity(
    id: '123',
    email: 'test@privaterelay.appleid.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime.now(),
  );

  test(
    'should return success and save user data when auth is successful',
    () async {
      when(
        mockAuthRepository.signInWithApple(),
      ).thenAnswer((_) async => AuthResult.success(user: tUser));
      when(
        mockUserRepository.saveUserData(any),
      ).thenAnswer((_) async => Future.value());

      final AuthResult result = await useCase();

      expect(result, AuthResult.success(user: tUser));
      await Future<void>.delayed(Duration.zero);
      verify(mockAuthRepository.signInWithApple()).called(1);
      verify(
        mockUserRepository.saveUserData(
          tUser,
          authProvider: 'apple',
          profileCompleted: true,
        ),
      ).called(1);
    },
  );

  test('should return failure when auth fails', () async {
    const tMessage = 'Sign in failed';
    const tCode = 'some_error';
    when(mockAuthRepository.signInWithApple()).thenAnswer(
      (_) async => const AuthResult.failure(message: tMessage, code: tCode),
    );

    final AuthResult result = await useCase();

    expect(result, const AuthResult.failure(message: tMessage, code: tCode));
    verify(mockAuthRepository.signInWithApple()).called(1);
    verifyNever(mockUserRepository.saveUserData(any));
  });

  test('should not call auth repository when offline', () async {
    networkInfo.connected = false;

    final AuthResult result = await useCase();

    expect(
      result,
      const AuthResult.failure(
        message: ServerActionFailureKey.offline,
        code: 'offline',
      ),
    );
    verifyNever(mockAuthRepository.signInWithApple());
    verifyNever(mockUserRepository.saveUserData(any));
  });

  test('should return cancelled without saving profile', () async {
    when(
      mockAuthRepository.signInWithApple(),
    ).thenAnswer((_) async => const AuthResult.cancelled());

    final AuthResult result = await useCase();

    expect(result, const AuthResult.cancelled());
    verify(mockAuthRepository.signInWithApple()).called(1);
    verifyNever(mockUserRepository.saveUserData(any));
  });
}
