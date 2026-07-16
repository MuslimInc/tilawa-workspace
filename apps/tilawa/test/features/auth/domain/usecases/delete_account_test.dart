import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/account_deletion_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'delete_account_test.mocks.dart';
import '../../../../support/fake_network_info.dart';

class _FakeResolveAuthenticatedUser extends ResolveAuthenticatedUserUseCase {
  _FakeResolveAuthenticatedUser(
    MockAuthRepository repository,
    this._resolvedUser,
  ) : super(repository, AwaitAuthRestorationUseCase(repository));

  final UserEntity? _resolvedUser;

  @override
  Future<UserEntity?> call({UserEntity? sessionUser}) async => _resolvedUser;
}

@GenerateMocks([
  AuthRepository,
  AccountDeletionRepository,
  SyncDeviceTokenUseCase,
  PremiumRepository,
])
void main() {
  late DeleteAccount useCase;
  late MockAuthRepository mockAuthRepository;
  late MockAccountDeletionRepository mockAccountDeletionRepository;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockPremiumRepository mockPremiumRepository;
  late FakeNetworkInfo networkInfo;
  late _FakeResolveAuthenticatedUser resolveAuthenticatedUser;

  final tUser = UserEntity(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    provideDummy<Either<Failure, void>>(const Right(null));
    mockAuthRepository = MockAuthRepository();
    mockAccountDeletionRepository = MockAccountDeletionRepository();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockPremiumRepository = MockPremiumRepository();
    networkInfo = FakeNetworkInfo();
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      tUser,
    );

    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    when(
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any),
    ).thenAnswer((_) async {
      return;
    });
    when(mockPremiumRepository.clearPremiumStatus()).thenAnswer((_) async {
      return;
    });
    when(
      mockAccountDeletionRepository.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(mockAuthRepository.signOut()).thenAnswer((_) async {
      return;
    });
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  test('returns ValidationFailure when no user is signed in', () async {
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      null,
    );
    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected left'),
    );
    verifyNever(
      mockAccountDeletionRepository.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    );
  });

  test('requests soft-delete then signs out', () async {
    final Either<Failure, void> result = await useCase();

    expect(result.isRight(), isTrue);
    verifyInOrder([
      mockAccountDeletionRepository.requestSelfAccountDeletion(
        reason: 'Self-service account deletion from mobile app',
        confirmEmail: 'test@example.com',
      ),
      mockSyncDeviceTokenUseCase.removeCurrentTokenForUser('user-1'),
      mockPremiumRepository.clearPremiumStatus(),
      mockAuthRepository.signOut(),
    ]);
  });

  test('returns offline failure without calling remote dependencies', () async {
    networkInfo.connected = false;

    final Either<Failure, void> result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerActionFailure>());
      expect(failure.message, ServerActionFailureKey.offline);
    }, (_) => fail('expected left'));
    verifyNever(
      mockAccountDeletionRepository.requestSelfAccountDeletion(
        reason: anyNamed('reason'),
        confirmEmail: anyNamed('confirmEmail'),
      ),
    );
    verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
    verifyNever(mockPremiumRepository.clearPremiumStatus());
    verifyNever(mockAuthRepository.signOut());
  });

  test('uses uid confirmation when email is missing', () async {
    resolveAuthenticatedUser = _FakeResolveAuthenticatedUser(
      mockAuthRepository,
      UserEntity(
        id: 'user-1',
        email: '',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024),
      ),
    );
    useCase = DeleteAccount(
      mockAuthRepository,
      mockAccountDeletionRepository,
      mockSyncDeviceTokenUseCase,
      mockPremiumRepository,
      ServerActionGuard(networkInfo),
      resolveAuthenticatedUser,
    );

    final Either<Failure, void> result = await useCase();

    expect(result.isRight(), isTrue);
    verify(
      mockAccountDeletionRepository.requestSelfAccountDeletion(
        reason: 'Self-service account deletion from mobile app',
        confirmEmail: 'user-1',
      ),
    ).called(1);
  });

  test(
    'does not clear session side effects when repository returns failure',
    () async {
      when(
        mockAccountDeletionRepository.requestSelfAccountDeletion(
          reason: anyNamed('reason'),
          confirmEmail: anyNamed('confirmEmail'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          PermissionFailure(DeleteAccountErrorKey.adminMustUseAdminPanel),
        ),
      );

      final Either<Failure, void> result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<PermissionFailure>());
        expect(
          failure.message,
          DeleteAccountErrorKey.adminMustUseAdminPanel,
        );
      }, (_) => fail('expected left'));
      verifyNever(mockSyncDeviceTokenUseCase.removeCurrentTokenForUser(any));
      verifyNever(mockPremiumRepository.clearPremiumStatus());
      verifyNever(mockAuthRepository.signOut());
    },
  );

  group('first-login session sync', () {
    late ResolveAuthenticatedUserUseCase resolveAuthenticatedUserUseCase;

    setUp(() {
      resolveAuthenticatedUserUseCase = ResolveAuthenticatedUserUseCase(
        mockAuthRepository,
        AwaitAuthRestorationUseCase(mockAuthRepository),
      );
      useCase = DeleteAccount(
        mockAuthRepository,
        mockAccountDeletionRepository,
        mockSyncDeviceTokenUseCase,
        mockPremiumRepository,
        ServerActionGuard(networkInfo),
        resolveAuthenticatedUserUseCase,
      );
    });

    test(
      'does not return notSignedIn when session hint syncs after delayed null',
      () async {
        final controller = StreamController<UserEntity?>.broadcast();
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => controller.stream,
        );

        final Future<Either<Failure, void>> pending = useCase(
          sessionUser: tUser,
        );
        await Future<void>.delayed(Duration.zero);
        controller.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.add(tUser);
        await controller.close();

        final Either<Failure, void> result = await pending;

        expect(result.isRight(), isTrue);
        verify(
          mockAccountDeletionRepository.requestSelfAccountDeletion(
            reason: 'Self-service account deletion from mobile app',
            confirmEmail: 'test@example.com',
          ),
        ).called(1);
      },
    );

    test(
      'does not return notSignedIn when session hint syncs on auth stream',
      () async {
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => Stream<UserEntity?>.value(tUser),
        );

        final Either<Failure, void> result = await useCase(
          sessionUser: tUser,
        );

        expect(result.isRight(), isTrue);
        verify(
          mockAccountDeletionRepository.requestSelfAccountDeletion(
            reason: 'Self-service account deletion from mobile app',
            confirmEmail: 'test@example.com',
          ),
        ).called(1);
      },
    );

    test(
      'returns notSignedIn when session hint never syncs to Firebase',
      () async {
        when(mockAuthRepository.currentUser).thenReturn(null);
        when(mockAuthRepository.authStateChanges).thenAnswer(
          (_) => const Stream<UserEntity?>.empty(),
        );

        final Either<Failure, void> result = await useCase(sessionUser: tUser);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, DeleteAccountErrorKey.notSignedIn);
        }, (_) => fail('expected left'));
        verifyNever(
          mockAccountDeletionRepository.requestSelfAccountDeletion(
            reason: anyNamed('reason'),
            confirmEmail: anyNamed('confirmEmail'),
          ),
        );
      },
      timeout: Timeout(
        ResolveAuthenticatedUserUseCase.postSignInSyncTimeout +
            const Duration(seconds: 2),
      ),
    );
  });
}
