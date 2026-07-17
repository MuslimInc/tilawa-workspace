import 'package:checks/checks.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFunctions functions;
  late _MockCallable callable;
  late _MockAuth auth;
  late _MockUser authUser;
  late FirebaseDeviceRegistryRepository repository;

  const userId = 'user_1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = _MockFunctions();
    callable = _MockCallable();
    auth = _MockAuth();
    authUser = _MockUser();
    when(() => functions.httpsCallable(any())).thenReturn(callable);
    when(() => auth.currentUser).thenReturn(authUser);
    when(() => authUser.uid).thenReturn(userId);
    when(() => authUser.getIdToken()).thenAnswer((_) async => 'id-token');
    repository = FirebaseDeviceRegistryRepository(
      firestore,
      _FakeDeviceIdentityService('device-current'),
      functions,
      auth,
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

  test(
    'getDevices returns unauthenticated when Auth has no live user',
    () async {
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.authStateChanges()).thenAnswer(
        (_) => const Stream<User?>.empty(),
      );

      final result = await repository.getDevices(userId);
      check(result.isLeft()).isTrue();
      check(
        result.fold((l) => l.message, (_) => null),
      ).equals('unauthenticated');
    },
  );

  group('management writes', () {
    test(
      'revokeDevice calls the callable and returns Right on success',
      () async {
        when(
          () => callable.call<Map<String, dynamic>>(any()),
        ).thenAnswer((_) async => _MockCallableResult());

        final result = await repository.revokeDevice('device-old');

        check(result.isRight()).isTrue();
        final captured = verify(
          () => functions.httpsCallable(captureAny()),
        ).captured;
        check(captured.single).equals('revokeDevice');
        verify(
          () => callable.call<Map<String, dynamic>>({'deviceId': 'device-old'}),
        ).called(1);
      },
    );

    test('signOutOtherDevices passes the current device id', () async {
      when(
        () => callable.call<Map<String, dynamic>>(any()),
      ).thenAnswer((_) async => _MockCallableResult());

      final result = await repository.signOutOtherDevices('device-current');

      check(result.isRight()).isTrue();
      verify(
        () => callable.call<Map<String, dynamic>>(
          {'currentDeviceId': 'device-current'},
        ),
      ).called(1);
    });

    test('maps a FirebaseFunctionsException to a Failure', () async {
      when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'nope', code: 'internal'),
      );

      final result = await repository.revokeDevice('device-old');
      check(result.isLeft()).isTrue();
    });
  });
}
