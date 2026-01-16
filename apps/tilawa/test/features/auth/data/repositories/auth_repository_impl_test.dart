import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/providers/auth_provider_factory.dart';
import 'package:tilawa/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/providers/auth_provider_interface.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([AuthProviderFactory, AuthProviderInterface, UserRepository])
void main() {
  late AuthRepositoryImpl authRepository;
  late MockAuthProviderFactory mockFactory;
  late MockAuthProviderInterface mockAuthProvider;

  setUp(() {
    mockFactory = MockAuthProviderFactory();
    mockAuthProvider = MockAuthProviderInterface();

    when(mockFactory.createAuthProvider()).thenReturn(mockAuthProvider);

    authRepository = AuthRepositoryImpl(mockFactory);
  });

  group('AuthRepositoryImpl', () {
    final tUser = UserEntity(
      id: '1',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.now(),
    );

    test('signInWithGoogle should return failure on error', () async {
      // Arrange
      when(
        mockAuthProvider.signIn(),
      ).thenAnswer((_) async => const AuthResult.failure(message: 'error'));

      // Act
      final AuthResult result = await authRepository.signInWithGoogle();

      // Assert
      expect(result, const AuthResult.failure(message: 'error'));
    });

    test('signInWithGoogle should return cancelled on cancellation', () async {
      // Arrange
      when(
        mockAuthProvider.signIn(),
      ).thenAnswer((_) async => const AuthResult.cancelled());

      // Act
      final AuthResult result = await authRepository.signInWithGoogle();

      // Assert
      expect(result, const AuthResult.cancelled());
    });

    test('authStateChanges should delegate to provider', () {
      // Arrange
      final stream = Stream<UserEntity?>.fromIterable([tUser]);
      when(mockAuthProvider.authStateChanges).thenAnswer((_) => stream);

      // Act
      final Stream<UserEntity?> result = authRepository.authStateChanges;

      // Assert
      expect(result, stream);
      verify(mockAuthProvider.authStateChanges);
    });

    test('signOut should delegate to provider', () async {
      // Act
      await authRepository.signOut();

      // Assert
      verify(mockAuthProvider.signOut()).called(1);
    });

    test('currentUser should delegate to provider', () {
      // Arrange
      when(mockAuthProvider.currentUser).thenReturn(tUser);

      // Act
      final UserEntity? result = authRepository.currentUser;

      // Assert
      expect(result, tUser);
      verify(mockAuthProvider.currentUser);
    });
  });
}
