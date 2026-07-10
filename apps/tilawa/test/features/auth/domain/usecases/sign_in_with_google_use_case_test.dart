import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../helpers/auth_mock_helper.mocks.dart';
import '../../../../support/fake_network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignInWithGoogleUseCase useCase;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    networkInfo = FakeNetworkInfo();
    useCase = SignInWithGoogleUseCase(
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
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'photo.jpg',
    createdAt: DateTime.now(),
  );

  test(
    'should return success and save user data when auth is successful',
    () async {
      // Arrange
      when(
        mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthResult.success(user: tUser));
      when(
        mockUserRepository.saveUserData(any),
      ).thenAnswer((_) async => Future.value());

      // Act
      final AuthResult result = await useCase();

      // Assert
      expect(result, AuthResult.success(user: tUser));
      await Future<void>.delayed(Duration.zero);
      verify(mockAuthRepository.signInWithGoogle()).called(1);
      verify(
        mockUserRepository.saveUserData(
          tUser,
          authProvider: 'google',
          profileCompleted: true,
        ),
      ).called(1);
    },
  );

  test(
    'should return success when auth succeeds but profile save fails',
    () async {
      when(
        mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => AuthResult.success(user: tUser));
      when(
        mockUserRepository.saveUserData(any),
      ).thenThrow(Exception('offline'));

      final AuthResult result = await useCase();

      expect(result, AuthResult.success(user: tUser));
      await Future<void>.delayed(Duration.zero);
      verify(
        mockUserRepository.saveUserData(
          tUser,
          authProvider: 'google',
          profileCompleted: true,
        ),
      ).called(1);
    },
  );

  test('should return failure when auth fails', () async {
    // Arrange
    const tMessage = 'Sign in failed';
    const tCode = 'some_error';
    when(mockAuthRepository.signInWithGoogle()).thenAnswer(
      (_) async => const AuthResult.failure(message: tMessage, code: tCode),
    );

    // Act
    final AuthResult result = await useCase();

    // Assert
    expect(result, const AuthResult.failure(message: tMessage, code: tCode));
    verify(mockAuthRepository.signInWithGoogle()).called(1);
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
    verifyNever(mockAuthRepository.signInWithGoogle());
    verifyNever(mockUserRepository.saveUserData(any));
  });
}
