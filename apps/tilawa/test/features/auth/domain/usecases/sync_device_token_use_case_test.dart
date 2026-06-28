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

  test('returns Right when registration succeeds', () async {
    when(
      () => mockRegister(tUserId),
    ).thenAnswer((_) async => const Right(tRegistration));

    final result = await useCase(tUserId);

    expect(result.isRight(), isTrue);
    verify(() => mockRegister(tUserId)).called(1);
  });

  test('swallows register failures without throwing', () async {
    when(() => mockRegister(tUserId)).thenAnswer(
      (_) async => Left(Failure.serverError('failed')),
    );

    final result = await useCase(tUserId);

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
    }, (_) => fail('expected Left'));
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
