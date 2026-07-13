import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_authenticated_user_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class _RecordingAwaitAuthRestoration extends AwaitAuthRestorationUseCase {
  _RecordingAwaitAuthRestoration(super.repository);

  int callCount = 0;
  @override
  Future<AuthRestorationOutcome> call({UserEntity? sessionUser}) async {
    callCount++;
    return AuthRestorationOutcome.unauthenticated;
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late _RecordingAwaitAuthRestoration awaitAuthRestoration;
  late ResolveAuthenticatedUserUseCase useCase;

  final UserEntity sessionUser = UserEntity(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    awaitAuthRestoration = _RecordingAwaitAuthRestoration(mockAuthRepository);
    useCase = ResolveAuthenticatedUserUseCase(
      mockAuthRepository,
      awaitAuthRestoration,
    );
  });

  test('returns live currentUser without waiting for restoration', () async {
    when(() => mockAuthRepository.currentUser).thenReturn(sessionUser);

    final UserEntity? result = await useCase(sessionUser: sessionUser);

    expect(result, sessionUser);
    expect(awaitAuthRestoration.callCount, 0);
    verifyNever(() => mockAuthRepository.authStateChanges);
  });

  test('returns user after auth restoration completes', () async {
    var reads = 0;
    when(() => mockAuthRepository.currentUser).thenAnswer((_) {
      reads++;
      return reads == 1 ? null : sessionUser;
    });

    final UserEntity? result = await useCase();

    expect(result, sessionUser);
    expect(awaitAuthRestoration.callCount, 1);
    verifyNever(() => mockAuthRepository.authStateChanges);
  });

  test(
    'waits for auth stream when session hint exists but live user is missing',
    () async {
      final controller = StreamController<UserEntity?>.broadcast();
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(
        () => mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final Future<UserEntity?> pending = useCase(sessionUser: sessionUser);
      await Future<void>.delayed(Duration.zero);
      controller.add(sessionUser);
      await controller.close();

      final UserEntity? result = await pending;

      expect(result, sessionUser);
      expect(awaitAuthRestoration.callCount, 1);
      verify(() => mockAuthRepository.authStateChanges).called(1);
    },
  );

  test(
    'waits for delayed auth stream user after null emission when session hint exists',
    () async {
      final controller = StreamController<UserEntity?>.broadcast();
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(
        () => mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final Future<UserEntity?> pending = useCase(sessionUser: sessionUser);
      await Future<void>.delayed(Duration.zero);
      controller.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(sessionUser);
      await controller.close();

      final UserEntity? result = await pending;

      expect(result, sessionUser);
      expect(awaitAuthRestoration.callCount, 1);
      verify(() => mockAuthRepository.authStateChanges).called(greaterThan(0));
    },
  );

  test(
    'returns null when no session hint and live user stays missing',
    () async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      final UserEntity? result = await useCase();

      expect(result, isNull);
      expect(awaitAuthRestoration.callCount, 1);
      verifyNever(() => mockAuthRepository.authStateChanges);
    },
  );

  test(
    'returns null when session hint never appears on auth stream',
    () async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(
        () => mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => const Stream<UserEntity?>.empty());

      final UserEntity? result = await useCase(sessionUser: sessionUser);

      expect(result, isNull);
      expect(awaitAuthRestoration.callCount, 1);
    },
    timeout: Timeout(
      ResolveAuthenticatedUserUseCase.postSignInSyncTimeout +
          const Duration(seconds: 1),
    ),
  );

  test(
    'ignores auth stream events for a different user id',
    () async {
      final controller = StreamController<UserEntity?>.broadcast();
      final UserEntity otherUser = UserEntity(
        id: 'other-user',
        email: 'other@example.com',
        displayName: 'Other',
        createdAt: DateTime.utc(2024),
      );
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(
        () => mockAuthRepository.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final Future<UserEntity?> pending = useCase(sessionUser: sessionUser);
      await Future<void>.delayed(Duration.zero);
      controller.add(otherUser);

      await Future<void>.delayed(
        ResolveAuthenticatedUserUseCase.postSignInSyncTimeout +
            const Duration(milliseconds: 100),
      );
      expect(await pending, isNull);
      await controller.close();
    },
    timeout: Timeout(
      ResolveAuthenticatedUserUseCase.postSignInSyncTimeout +
          const Duration(seconds: 2),
    ),
  );
}
