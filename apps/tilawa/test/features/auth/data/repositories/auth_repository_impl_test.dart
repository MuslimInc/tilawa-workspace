import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/gateways/email_password_auth_gateway.dart';
import 'package:tilawa/features/auth/data/datasources/google_sign_in_prepare_data_source.dart';
import 'package:tilawa/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/providers/auth_provider_interface.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([
  AuthProviderInterface,
  UserRepository,
  GoogleSignInPrepareDataSource,
  EmailPasswordAuthGateway,
])
void main() {
  late AuthRepositoryImpl authRepository;
  late MockAuthProviderInterface mockAuthProvider;
  late MockGoogleSignInPrepareDataSource mockPrepare;
  late MockEmailPasswordAuthGateway mockEmailAuth;

  setUp(() {
    mockAuthProvider = MockAuthProviderInterface();
    mockPrepare = MockGoogleSignInPrepareDataSource();
    mockEmailAuth = MockEmailPasswordAuthGateway();

    when(mockPrepare.prepare()).thenAnswer((_) async {});
    when(mockPrepare.ensureInitialized()).thenAnswer((_) async {});

    authRepository = AuthRepositoryImpl(
      mockAuthProvider,
      mockPrepare,
      mockEmailAuth,
    );
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

    test('signInWithGoogle should prepare before signing in', () async {
      when(
        mockAuthProvider.signIn(),
      ).thenAnswer((_) async => AuthResult.success(user: tUser));

      await authRepository.signInWithGoogle();

      verifyInOrder([mockPrepare.prepare(), mockAuthProvider.signIn()]);
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

    test(
      'signOut should ensure initialization and delegate to provider',
      () async {
        await authRepository.signOut();

        verifyInOrder([
          mockPrepare.ensureInitialized(),
          mockAuthProvider.signOut(),
        ]);
      },
    );

    test(
      'deleteAccount should ensure initialization before deleting',
      () async {
        when(mockAuthProvider.deleteAccount()).thenAnswer((_) async {});

        await authRepository.deleteAccount();

        verifyInOrder([
          mockPrepare.ensureInitialized(),
          mockAuthProvider.deleteAccount(),
        ]);
      },
    );

    test('signOut should still sign out when initialization fails', () async {
      when(mockPrepare.ensureInitialized()).thenThrow(Exception('init failed'));

      await authRepository.signOut();

      verify(mockAuthProvider.signOut()).called(1);
    });

    test('prepareGoogleSignIn should delegate to data source', () async {
      await authRepository.prepareGoogleSignIn();

      verify(mockPrepare.prepare()).called(1);
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

    test('hasAdminClaim should delegate to provider', () async {
      when(mockAuthProvider.hasAdminClaim()).thenAnswer((_) async => true);

      final bool result = await authRepository.hasAdminClaim();

      expect(result, isTrue);
      verify(mockAuthProvider.hasAdminClaim()).called(1);
    });
  });
}
