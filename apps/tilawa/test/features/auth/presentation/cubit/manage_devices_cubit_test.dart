import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/registered_device.dart';
import 'package:tilawa/features/auth/domain/repositories/device_registry_repository.dart';
import 'package:tilawa/features/auth/presentation/cubit/manage_devices_cubit.dart';
import 'package:tilawa_core/errors/failures.dart';

/// In-memory fake — the registry the server would own. Revoking flips a flag so
/// a post-write reload reflects it (mirrors server truth).
class _FakeDeviceRegistryRepository implements DeviceRegistryRepository {
  _FakeDeviceRegistryRepository(this._devices);

  List<RegisteredDevice> _devices;
  final String currentId = 'device-a';
  bool failWrites = false;

  @override
  Future<String> currentDeviceId() async => currentId;

  @override
  Future<Either<Failure, List<RegisteredDevice>>> getDevices(
    String userId,
  ) async => Right(List.of(_devices));

  @override
  Future<Either<Failure, void>> revokeDevice(String deviceId) async {
    if (failWrites) return Left(Failure.serverError('nope'));
    _devices = _devices
        .map(
          (d) => d.deviceId == deviceId
              ? RegisteredDevice(
                  deviceId: d.deviceId,
                  platform: d.platform,
                  isRevoked: true,
                )
              : d,
        )
        .toList();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> signOutOtherDevices(
    String currentDeviceId,
  ) async {
    if (failWrites) return Left(Failure.serverError('nope'));
    _devices = _devices
        .map(
          (d) => d.deviceId == currentDeviceId
              ? d
              : RegisteredDevice(
                  deviceId: d.deviceId,
                  platform: d.platform,
                  isRevoked: true,
                ),
        )
        .toList();
    return const Right(null);
  }
}

RegisteredDevice device(String id, {bool revoked = false}) =>
    RegisteredDevice(deviceId: id, platform: 'android', isRevoked: revoked);

void main() {
  const userId = 'user_1';

  test('load populates devices and flags the current device', () async {
    final repo = _FakeDeviceRegistryRepository([
      device('device-a'),
      device('device-b'),
    ]);
    final cubit = ManageDevicesCubit(repo);

    await cubit.load(userId);

    check(cubit.state.status).equals(ManageDevicesStatus.loaded);
    check(cubit.state.currentDeviceId).equals('device-a');
    check(cubit.state.devices).length.equals(2);
    check(cubit.state.isCurrent(device('device-a'))).isTrue();
    check(cubit.state.hasOtherActiveDevices).isTrue();
    await cubit.close();
  });

  test('signOutDevice refuses to sign out the current device', () async {
    final repo = _FakeDeviceRegistryRepository([device('device-a')]);
    final cubit = ManageDevicesCubit(repo);
    await cubit.load(userId);

    final ok = await cubit.signOutDevice(userId, 'device-a');
    check(ok).isFalse();
    check(cubit.state.devices.single.isRevoked).isFalse();
    await cubit.close();
  });

  test('signOutDevice revokes another device and refreshes', () async {
    final repo = _FakeDeviceRegistryRepository([
      device('device-a'),
      device('device-b'),
    ]);
    final cubit = ManageDevicesCubit(repo);
    await cubit.load(userId);

    final ok = await cubit.signOutDevice(userId, 'device-b');

    check(ok).isTrue();
    final b = cubit.state.devices.firstWhere((d) => d.deviceId == 'device-b');
    check(b.isRevoked).isTrue();
    check(cubit.state.busyDeviceIds).isEmpty();
    check(cubit.state.hasOtherActiveDevices).isFalse();
    await cubit.close();
  });

  test(
    'signOutOtherDevices revokes everything but the current device',
    () async {
      final repo = _FakeDeviceRegistryRepository([
        device('device-a'),
        device('device-b'),
        device('device-c'),
      ]);
      final cubit = ManageDevicesCubit(repo);
      await cubit.load(userId);

      final ok = await cubit.signOutOtherDevices(userId);

      check(ok).isTrue();
      check(cubit.state.signingOutOthers).isFalse();
      final current = cubit.state.devices.firstWhere(
        (d) => d.deviceId == 'device-a',
      );
      check(current.isRevoked).isFalse();
      check(cubit.state.otherActiveDevices).isEmpty();
      await cubit.close();
    },
  );

  test('a failed write returns false and does not throw', () async {
    final repo = _FakeDeviceRegistryRepository([
      device('device-a'),
      device('device-b'),
    ])..failWrites = true;
    final cubit = ManageDevicesCubit(repo);
    await cubit.load(userId);

    check(await cubit.signOutDevice(userId, 'device-b')).isFalse();
    check(await cubit.signOutOtherDevices(userId)).isFalse();
    await cubit.close();
  });

  test('load surfaces an error status when the read fails', () async {
    final repo = _ErroringRepo();
    final cubit = ManageDevicesCubit(repo);
    await cubit.load(userId);
    check(cubit.state.status).equals(ManageDevicesStatus.error);
    await cubit.close();
  });
}

class _ErroringRepo implements DeviceRegistryRepository {
  @override
  Future<String> currentDeviceId() async => 'device-a';

  @override
  Future<Either<Failure, List<RegisteredDevice>>> getDevices(
    String userId,
  ) async => Left(Failure.serverError('boom'));

  @override
  Future<Either<Failure, void>> revokeDevice(String deviceId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> signOutOtherDevices(
    String currentDeviceId,
  ) async => const Right(null);
}
