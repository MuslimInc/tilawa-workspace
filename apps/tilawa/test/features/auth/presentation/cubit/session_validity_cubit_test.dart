import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCheckSessionValidityUseCase extends Mock
    implements CheckSessionValidityUseCase {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockCheckSessionValidityUseCase mockCheckValidity;
  late MockSignOut mockSignOut;
  late SessionRevokedNotifier sessionRevokedNotifier;

  final tUser = UserEntity(
    id: 'user_1',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockCheckValidity = MockCheckSessionValidityUseCase();
    mockSignOut = MockSignOut();
    sessionRevokedNotifier = SessionRevokedNotifier();

    when(() => mockAuthRepository.currentUser).thenReturn(tUser);
    when(() => mockSignOut()).thenAnswer((_) async {});
  });

  tearDown(() {
    sessionRevokedNotifier.resetDedupeForTest();
  });

  SessionValidityCubit buildCubit() => SessionValidityCubit(
    mockAuthRepository,
    mockCheckValidity,
    mockSignOut,
    sessionRevokedNotifier,
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'checkOnResume signs out when background session_revoked flag is set',
    build: buildCubit,
    setUp: () {
      SharedPreferences.setMockInitialValues({
        PendingSessionRevokeStore.key: true,
      });
    },
    act: (cubit) async {
      await cubit.checkOnResume();
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const SessionValidityState(revoked: true, isChecking: false),
    ],
    verify: (_) {
      verify(() => mockSignOut()).called(1);
      verifyNever(() => mockCheckValidity(any()));
    },
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'checkOnResume signs out when server epoch is stale',
    build: buildCubit,
    act: (cubit) async {
      when(
        () => mockCheckValidity('user_1'),
      ).thenAnswer((_) async => const Right(false));
      await cubit.checkOnResume();
    },
    expect: () => [
      const SessionValidityState(isChecking: true),
      const SessionValidityState(isChecking: false),
      const SessionValidityState(revoked: true, isChecking: false),
    ],
    verify: (_) {
      verify(() => mockSignOut()).called(1);
    },
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'checkOnResume keeps session when epoch matches',
    build: buildCubit,
    act: (cubit) async {
      when(
        () => mockCheckValidity('user_1'),
      ).thenAnswer((_) async => const Right(true));
      await cubit.checkOnResume();
    },
    expect: () => [
      const SessionValidityState(isChecking: true),
      const SessionValidityState(isChecking: false),
    ],
    verify: (_) {
      verifyNever(() => mockSignOut());
    },
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'checkOnResume is no-op when user is signed out',
    build: () {
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      return buildCubit();
    },
    act: (cubit) async => cubit.checkOnResume(),
    expect: () => <SessionValidityState>[],
    verify: (_) {
      verifyNever(() => mockCheckValidity(any()));
    },
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'FCM session_revoked triggers sign-out once',
    build: buildCubit,
    act: (cubit) async {
      sessionRevokedNotifier.notifySessionRevoked();
      sessionRevokedNotifier.notifySessionRevoked();
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const SessionValidityState(revoked: true, isChecking: false),
    ],
    verify: (_) {
      verify(() => mockSignOut()).called(1);
    },
  );

  blocTest<SessionValidityCubit, SessionValidityState>(
    'checkOnResume treats validity check errors as still valid',
    build: buildCubit,
    act: (cubit) async {
      when(() => mockCheckValidity('user_1')).thenAnswer(
        (_) async => Left(Failure.unexpectedError('offline')),
      );
      await cubit.checkOnResume();
    },
    expect: () => [
      const SessionValidityState(isChecking: true),
      const SessionValidityState(isChecking: false),
    ],
    verify: (_) {
      verifyNever(() => mockSignOut());
    },
  );

  test('close cancels session revoked subscription', () async {
    final cubit = buildCubit();
    await cubit.close();

    sessionRevokedNotifier.notifySessionRevoked();
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => mockSignOut());
  });

  test('SessionValidityState copyWith updates revoked flag', () {
    const state = SessionValidityState(isChecking: true);
    final updated = state.copyWith(revoked: true, isChecking: false);

    expect(updated.revoked, isTrue);
    expect(updated.isChecking, isFalse);
  });

  test('revoked cubit ignores subsequent resume checks', () async {
    final cubit = buildCubit();
    when(
      () => mockCheckValidity('user_1'),
    ).thenAnswer((_) async => const Right(false));
    await cubit.checkOnResume();
    clearInteractions(mockCheckValidity);

    await cubit.checkOnResume();

    verifyNever(() => mockCheckValidity(any()));
    expect(cubit.state.revoked, isTrue);
    await cubit.close();
  });
}
