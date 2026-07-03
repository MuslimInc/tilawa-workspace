import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AwaitAuthRestorationUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = AwaitAuthRestorationUseCase(mockAuthRepository);
  });

  test('completes when auth stream emits', () async {
    final controller = StreamController<UserEntity?>();
    when(() => mockAuthRepository.authStateChanges).thenAnswer(
      (_) => controller.stream,
    );
    when(() => mockAuthRepository.currentUser).thenReturn(null);

    final Future<void> pending = useCase();
    await Future<void>.delayed(Duration.zero);
    controller.add(null);
    await controller.close();
    await pending;

    verify(() => mockAuthRepository.authStateChanges).called(1);
  });

  test('completes on timeout without throwing', () async {
    when(() => mockAuthRepository.authStateChanges).thenAnswer(
      (_) => const Stream<UserEntity?>.empty(),
    );
    when(() => mockAuthRepository.currentUser).thenReturn(null);

    await useCase();

    verify(() => mockAuthRepository.authStateChanges).called(1);
  });

  test(
    'skips auth stream wait when currentUser is already available',
    () async {
      when(() => mockAuthRepository.currentUser).thenReturn(
        UserEntity(
          id: 'user_1',
          email: 'user@example.com',
          displayName: 'User',
          createdAt: DateTime.utc(2024),
        ),
      );

      await useCase();

      verifyNever(() => mockAuthRepository.authStateChanges);
    },
  );

  test(
    'waits for session user after initial null emission when hint provided',
    () async {
      final controller = StreamController<UserEntity?>.broadcast();
      final UserEntity sessionUser = UserEntity(
        id: 'user_1',
        email: 'user@example.com',
        displayName: 'User',
        createdAt: DateTime.utc(2024),
      );
      when(() => mockAuthRepository.authStateChanges).thenAnswer(
        (_) => controller.stream,
      );
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      final Future<void> pending = useCase(sessionUser: sessionUser);
      await Future<void>.delayed(Duration.zero);
      controller.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(sessionUser);
      await controller.close();
      await pending;

      verify(() => mockAuthRepository.authStateChanges).called(greaterThan(0));
    },
  );

  test(
    'timeout does not block callers when currentUser is already set',
    () async {
      when(() => mockAuthRepository.authStateChanges).thenAnswer(
        (_) => const Stream<UserEntity?>.empty(),
      );
      when(() => mockAuthRepository.currentUser).thenReturn(
        UserEntity(
          id: 'user_1',
          email: 'user@example.com',
          displayName: 'User',
          createdAt: DateTime.utc(2024),
        ),
      );

      await useCase();

      verifyNever(() => mockAuthRepository.authStateChanges);
    },
  );
}
