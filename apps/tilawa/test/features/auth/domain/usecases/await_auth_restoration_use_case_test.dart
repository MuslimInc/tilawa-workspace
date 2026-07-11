import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

UserEntity _user([String id = 'user_1']) => UserEntity(
  id: id,
  email: 'user@example.com',
  displayName: 'User',
  createdAt: DateTime.utc(2024),
);

void main() {
  late MockAuthRepository mockAuthRepository;
  late AwaitAuthRestorationUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = AwaitAuthRestorationUseCase(mockAuthRepository);
  });

  test('restored immediately when currentUser is already available', () async {
    when(() => mockAuthRepository.currentUser).thenReturn(_user());

    final outcome = await useCase();

    expect(outcome, AuthRestorationOutcome.restored);
    verifyNever(() => mockAuthRepository.authStateChanges);
  });

  test(
    'unauthenticated on the first null emission when no persisted hint',
    () async {
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.authStateChanges).thenAnswer(
        (_) => Stream<UserEntity?>.value(null),
      );

      final outcome = await useCase();

      expect(outcome, AuthRestorationOutcome.unauthenticated);
      // No hint → the first determined emission is authoritative; the login
      // path is not stalled waiting for a non-null user.
      verify(() => mockAuthRepository.authStateChanges).called(1);
    },
  );

  test(
    'restored after a premature null emission when a hint is provided '
    '(cold-start race regression)',
    () async {
      final controller = StreamController<UserEntity?>.broadcast();
      final UserEntity sessionUser = _user();
      when(() => mockAuthRepository.authStateChanges).thenAnswer(
        (_) => controller.stream,
      );
      // currentUser is null at read time (native restore not finished), then
      // becomes non-null once the persisted user loads.
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      final Future<AuthRestorationOutcome> pending = useCase(
        sessionUser: sessionUser,
      );
      await Future<void>.delayed(Duration.zero);
      controller.add(null); // FlutterFire premature null
      await Future<void>.delayed(const Duration(milliseconds: 20));
      when(() => mockAuthRepository.currentUser).thenReturn(sessionUser);
      controller.add(sessionUser); // real restored user
      final outcome = await pending;
      await controller.close();

      expect(outcome, AuthRestorationOutcome.restored);
    },
  );

  test(
    'pendingUnresolved (never unauthenticated) when a hinted restore does not '
    'surface a user',
    () async {
      final controller = StreamController<UserEntity?>();
      when(() => mockAuthRepository.authStateChanges).thenAnswer(
        (_) => controller.stream,
      );
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      final Future<AuthRestorationOutcome> pending = useCase(
        sessionUser: _user(),
      );
      await Future<void>.delayed(Duration.zero);
      // Stream closes without ever emitting a non-null user (worst-case race).
      await controller.close();
      final outcome = await pending;

      // A persisted user is presumed intact; a transient race is NOT a logout.
      expect(outcome, AuthRestorationOutcome.pendingUnresolved);
    },
  );
}
