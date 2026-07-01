import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/entities/session_registration.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';
import 'package:tilawa/features/auth/domain/usecases/register_active_device_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockRegisterActiveDeviceUseCase extends Mock
    implements RegisterActiveDeviceUseCase {}

void main() {
  late MockRegisterActiveDeviceUseCase mockRegisterActiveDevice;
  late SessionRevokedNotifier sessionRevokedNotifier;
  late SyncDeviceTokenUseCase useCase;

  setUp(() {
    mockRegisterActiveDevice = MockRegisterActiveDeviceUseCase();
    sessionRevokedNotifier = SessionRevokedNotifier();
    useCase = SyncDeviceTokenUseCase(
      mockRegisterActiveDevice,
      sessionRevokedNotifier,
    );
  });

  tearDown(() {
    sessionRevokedNotifier.resetDedupeForTest();
  });

  test('call performs passive sync', () async {
    when(() => mockRegisterActiveDevice.syncPassive('user_1')).thenAnswer(
      (_) async => const Right(
        SessionRegistration(
          status: SessionRegistrationStatus.updatedSameDevice,
          sessionEpoch: 1,
          activeDeviceId: 'device_1',
        ),
      ),
    );

    final result = await useCase('user_1');

    expect(result.isRight(), isTrue);
    verify(() => mockRegisterActiveDevice.syncPassive('user_1')).called(1);
  });

  test('registerExplicitSignIn forwards explicit registration', () async {
    when(
      () => mockRegisterActiveDevice.registerExplicitSignIn('user_1'),
    ).thenAnswer(
      (_) async => const Right(
        SessionRegistration(
          status: SessionRegistrationStatus.registered,
          sessionEpoch: 2,
          activeDeviceId: 'device_1',
        ),
      ),
    );

    final result = await useCase.registerExplicitSignIn('user_1');

    expect(result.isRight(), isTrue);
    verify(
      () => mockRegisterActiveDevice.registerExplicitSignIn('user_1'),
    ).called(1);
  });

  test('passive stale failure notifies session revoked', () async {
    var revoked = false;
    final subscription = sessionRevokedNotifier.onSessionRevoked.listen((_) {
      revoked = true;
    });
    when(() => mockRegisterActiveDevice.syncPassive('user_1')).thenAnswer(
      (_) async => const Left(
        PermissionFailure(AuthErrorKey.staleDeviceRejected),
      ),
    );

    final result = await useCase('user_1');
    await Future<void>.delayed(Duration.zero);

    expect(result.isLeft(), isTrue);
    expect(revoked, isTrue);
    await subscription.cancel();
  });

  test('explicit stale failure notifies session revoked', () async {
    var revoked = false;
    final subscription = sessionRevokedNotifier.onSessionRevoked.listen((_) {
      revoked = true;
    });
    when(
      () => mockRegisterActiveDevice.registerExplicitSignIn('user_1'),
    ).thenAnswer(
      (_) async => const Left(
        PermissionFailure(AuthErrorKey.staleDeviceRejected),
      ),
    );

    final result = await useCase.registerExplicitSignIn('user_1');
    await Future<void>.delayed(Duration.zero);

    expect(result.isLeft(), isTrue);
    expect(revoked, isTrue);
    await subscription.cancel();
  });

  test('requiresExplicitSignIn does not notify session revoked', () async {
    var revoked = false;
    final subscription = sessionRevokedNotifier.onSessionRevoked.listen((_) {
      revoked = true;
    });
    when(() => mockRegisterActiveDevice.syncPassive('user_1')).thenAnswer(
      (_) async => const Left(
        PermissionFailure(AuthErrorKey.requiresExplicitSignIn),
      ),
    );

    final result = await useCase('user_1');
    await Future<void>.delayed(Duration.zero);

    expect(result.isLeft(), isTrue);
    expect(revoked, isFalse);
    await subscription.cancel();
  });
}
