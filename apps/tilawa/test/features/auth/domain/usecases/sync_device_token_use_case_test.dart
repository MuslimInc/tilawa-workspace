import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/session_registration.dart';
import 'package:tilawa/features/auth/domain/usecases/register_active_device_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockRegisterActiveDeviceUseCase extends Mock
    implements RegisterActiveDeviceUseCase {}

void main() {
  late SyncDeviceTokenUseCase useCase;
  late MockRegisterActiveDeviceUseCase mockRegister;

  const tUserId = 'user_123';
  const tRegistration = SessionRegistration(
    epoch: 1,
    activeDeviceId: 'device_1',
  );

  setUp(() {
    mockRegister = MockRegisterActiveDeviceUseCase();
    useCase = SyncDeviceTokenUseCase(mockRegister);
  });

  test('delegates registration to RegisterActiveDeviceUseCase', () async {
    when(
      () => mockRegister(tUserId),
    ).thenAnswer((_) async => const Right(tRegistration));

    await useCase(tUserId);

    verify(() => mockRegister(tUserId)).called(1);
  });

  test('swallows register failures without throwing', () async {
    when(() => mockRegister(tUserId)).thenAnswer(
      (_) async => Left(Failure.serverError('failed')),
    );

    await expectLater(useCase(tUserId), completes);
  });

  test(
    'removeCurrentTokenForUser clears active device via register use case',
    () async {
      when(
        () => mockRegister.clearActiveDeviceOnSignOut(tUserId),
      ).thenAnswer((_) async => const Right(null));

      await useCase.removeCurrentTokenForUser(tUserId);

      verify(() => mockRegister.clearActiveDeviceOnSignOut(tUserId)).called(1);
    },
  );
}
