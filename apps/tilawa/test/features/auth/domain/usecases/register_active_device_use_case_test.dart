import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/data/datasources/active_device_remote_data_source.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';
import 'package:tilawa/features/auth/domain/entities/session_registration.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/register_active_device_use_case.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

class MockActiveDeviceRemoteDataSource extends Mock
    implements ActiveDeviceRemoteDataSource {}

class MockDeviceIdentityService extends Mock implements DeviceIdentityService {}

class MockDeviceTokenService extends Mock implements DeviceTokenService {}

class MockTokenSyncCache extends Mock implements TokenSyncCache {}

class MockAppInfoService extends Mock implements AppInfoService {}

void main() {
  late RegisterActiveDeviceUseCase useCase;
  late MockActiveDeviceRemoteDataSource mockRemote;
  late MockDeviceIdentityService mockIdentity;
  late MockDeviceTokenService mockTokenService;
  late MockTokenSyncCache mockCache;
  late MockAppInfoService mockAppInfo;

  const tUserId = 'user_1';
  const tToken = 'fcm_token';
  const tRegistration = SessionRegistration(
    epoch: 2,
    activeDeviceId: 'device_1',
  );

  setUp(() {
    mockRemote = MockActiveDeviceRemoteDataSource();
    mockIdentity = MockDeviceIdentityService();
    mockTokenService = MockDeviceTokenService();
    mockCache = MockTokenSyncCache();
    mockAppInfo = MockAppInfoService();

    useCase = RegisterActiveDeviceUseCase(
      mockRemote,
      mockIdentity,
      mockTokenService,
      mockCache,
      mockAppInfo,
    );

    when(() => mockIdentity.platform).thenReturn('android');
    when(() => mockIdentity.getDeviceId()).thenAnswer((_) async => 'device_1');
    when(() => mockAppInfo.getAppInfo()).thenAnswer(
      (_) async => const AppInfo(
        version: '2.0.0',
        buildNumber: '1',
        appName: 'Tilawa',
        packageName: 'com.tilawa',
      ),
    );
    when(() => mockCache.saveSync(any(), any())).thenAnswer((_) async {});
    when(() => mockCache.saveSessionEpoch(any())).thenAnswer((_) async {});
    when(() => mockCache.saveActiveDeviceId(any())).thenAnswer((_) async {});
  });

  test('returns Right and caches epoch on successful registration', () async {
    when(() => mockTokenService.getToken()).thenAnswer((_) async => tToken);
    when(
      () => mockRemote.registerActiveDevice(
        deviceId: any(named: 'deviceId'),
        fcmToken: any(named: 'fcmToken'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        signOut: any(named: 'signOut'),
      ),
    ).thenAnswer((_) async => tRegistration);

    final result = await useCase(tUserId);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected Right'), (registration) {
      expect(registration, tRegistration);
    });
    verify(() => mockCache.saveSessionEpoch(2)).called(1);
    verify(() => mockCache.saveActiveDeviceId('device_1')).called(1);
    verify(() => mockCache.saveSync(tToken, tUserId)).called(1);
  });

  test('returns validation failure when FCM token missing', () async {
    when(() => mockTokenService.getToken()).thenAnswer((_) async => null);

    final result = await useCase(tUserId);

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => mockRemote.registerActiveDevice(
        deviceId: any(named: 'deviceId'),
        fcmToken: any(named: 'fcmToken'),
        platform: any(named: 'platform'),
      ),
    );
  });

  test('returns server failure when callable throws', () async {
    when(() => mockTokenService.getToken()).thenAnswer((_) async => tToken);
    when(
      () => mockRemote.registerActiveDevice(
        deviceId: any(named: 'deviceId'),
        fcmToken: any(named: 'fcmToken'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        signOut: any(named: 'signOut'),
      ),
    ).thenThrow(
      FirebaseFunctionsException(
        code: 'internal',
        message: 'boom',
      ),
    );

    final result = await useCase(tUserId);

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
    }, (_) => fail('expected Left'));
  });

  test('clearActiveDeviceOnSignOut clears local session cache', () async {
    when(
      () => mockCache.getActiveDeviceId(),
    ).thenAnswer((_) async => 'device_1');
    when(
      () => mockRemote.registerActiveDevice(
        deviceId: any(named: 'deviceId'),
        fcmToken: any(named: 'fcmToken'),
        platform: any(named: 'platform'),
        signOut: true,
      ),
    ).thenAnswer(
      (_) async =>
          const SessionRegistration(epoch: 2, activeDeviceId: 'device_1'),
    );
    when(() => mockCache.clearSession()).thenAnswer((_) async {});

    final result = await useCase.clearActiveDeviceOnSignOut(tUserId);

    expect(result.isRight(), isTrue);
    verify(() => mockCache.clearSession()).called(1);
  });

  test('returns unexpected failure when device identity throws', () async {
    when(() => mockTokenService.getToken()).thenAnswer((_) async => tToken);
    when(() => mockIdentity.getDeviceId()).thenThrow(Exception('fid failed'));

    final result = await useCase(tUserId);

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<UnexpectedFailure>());
    }, (_) => fail('expected Left'));
  });

  test(
    'clearActiveDeviceOnSignOut falls back to device identity when cache empty',
    () async {
      when(() => mockCache.getActiveDeviceId()).thenAnswer((_) async => null);
      when(() => mockIdentity.getDeviceId()).thenAnswer((_) async => 'fid_2');
      when(
        () => mockRemote.registerActiveDevice(
          deviceId: 'fid_2',
          fcmToken: '',
          platform: 'android',
          signOut: true,
        ),
      ).thenAnswer(
        (_) async =>
            const SessionRegistration(epoch: 2, activeDeviceId: 'fid_2'),
      );
      when(() => mockCache.clearSession()).thenAnswer((_) async {});

      final result = await useCase.clearActiveDeviceOnSignOut(tUserId);

      expect(result.isRight(), isTrue);
      verify(() => mockCache.clearSession()).called(1);
    },
  );

  test(
    'clearActiveDeviceOnSignOut clears local session when remote throws',
    () async {
      when(
        () => mockCache.getActiveDeviceId(),
      ).thenAnswer((_) async => 'device_1');
      when(
        () => mockRemote.registerActiveDevice(
          deviceId: any(named: 'deviceId'),
          fcmToken: any(named: 'fcmToken'),
          platform: any(named: 'platform'),
          signOut: true,
        ),
      ).thenThrow(Exception('network'));
      when(() => mockCache.clearSession()).thenAnswer((_) async {});

      final result = await useCase.clearActiveDeviceOnSignOut(tUserId);

      expect(result.isRight(), isTrue);
      verify(() => mockCache.clearSession()).called(1);
    },
  );

  test(
    'token refresh on same device updates cache without epoch change',
    () async {
      when(
        () => mockTokenService.getToken(),
      ).thenAnswer((_) async => 'fcm_new');
      when(
        () => mockRemote.registerActiveDevice(
          deviceId: 'device_1',
          fcmToken: 'fcm_new',
          platform: 'android',
          appVersion: any(named: 'appVersion'),
          signOut: false,
        ),
      ).thenAnswer(
        (_) async =>
            const SessionRegistration(epoch: 5, activeDeviceId: 'device_1'),
      );

      final result = await useCase(tUserId);

      expect(result.isRight(), isTrue);
      verify(() => mockCache.saveSessionEpoch(5)).called(1);
      verify(() => mockCache.saveSync('fcm_new', tUserId)).called(1);
    },
  );
}
