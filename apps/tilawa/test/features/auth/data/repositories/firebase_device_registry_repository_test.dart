import 'package:checks/checks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/data/repositories/firebase_device_registry_repository.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';

class _FakeDeviceIdentityService implements DeviceIdentityService {
  _FakeDeviceIdentityService(this._id);

  final String _id;

  @override
  Future<String> getDeviceId() async => _id;

  @override
  String get platform => 'android';
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseDeviceRegistryRepository repository;

  const userId = 'user_1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseDeviceRegistryRepository(
      firestore,
      _FakeDeviceIdentityService('device-current'),
    );
  });

  Future<void> seedDevice(
    String deviceId, {
    required DateTime lastSeenAt,
    Map<String, dynamic>? deviceInfo,
    DateTime? revokedAt,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .set({
          'platform': 'android',
          'appVersion': '2.0.0',
          'lastSeenAt': lastSeenAt,
          'createdAt': lastSeenAt,
          'revokedAt': revokedAt,
          'deviceInfo': ?deviceInfo,
        });
  }

  test('currentDeviceId delegates to the device identity service', () async {
    check(await repository.currentDeviceId()).equals('device-current');
  });

  test('getDevices returns an empty list when none are registered', () async {
    final result = await repository.getDevices(userId);
    check(result.isRight()).isTrue();
    check(result.getOrElse(() => [])).isEmpty();
  });

  test('getDevices maps fields and sorts by lastSeenAt descending', () async {
    await seedDevice(
      'device-old',
      lastSeenAt: DateTime.utc(2026, 7, 1, 10),
      deviceInfo: {'manufacturer': 'OPPO', 'model': 'A98 5G'},
    );
    await seedDevice(
      'device-new',
      lastSeenAt: DateTime.utc(2026, 7, 5, 10),
    );

    final result = await repository.getDevices(userId);
    final devices = result.getOrElse(() => []);

    check(devices.map((d) => d.deviceId).toList()).deepEquals([
      'device-new',
      'device-old',
    ]);

    final old = devices.firstWhere((d) => d.deviceId == 'device-old');
    check(old.platform).equals('android');
    check(old.appVersion).equals('2.0.0');
    check(old.label).equals('OPPO A98 5G');
    check(old.isRevoked).isFalse();
  });

  test('getDevices flags a revoked device', () async {
    await seedDevice(
      'device-revoked',
      lastSeenAt: DateTime.utc(2026, 7, 2, 10),
      revokedAt: DateTime.utc(2026, 7, 3, 10),
    );

    final result = await repository.getDevices(userId);
    final devices = result.getOrElse(() => []);

    check(devices).length.equals(1);
    check(devices.single.isRevoked).isTrue();
  });
}
