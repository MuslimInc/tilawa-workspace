import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/entities/device_info_snapshot.dart';
import 'package:tilawa/features/auth/domain/entities/session_registration.dart';
import 'package:tilawa/features/auth/domain/repositories/active_device_repository.dart';
import 'package:tilawa/features/auth/domain/services/device_info_service.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/register_active_device_use_case.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

class MockActiveDeviceRepository extends Mock
    implements ActiveDeviceRepository {}

class MockDeviceTokenService extends Mock implements DeviceTokenService {}

class MockTokenSyncCache extends Mock implements TokenSyncCache {}

class MockAppInfoService extends Mock implements AppInfoService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

void main() {
  late RegisterActiveDeviceUseCase useCase;
  late MockActiveDeviceRepository mockRepository;
  late MockDeviceTokenService mockTokenService;
  late MockTokenSyncCache mockCache;
  late MockAppInfoService mockAppInfo;
  late MockDeviceInfoService mockDeviceInfo;

  const tUserId = 'user_1';
  const tToken = 'fcm_token';
  const tDeviceInfo = DeviceInfoSnapshot(
    manufacturer: 'OPPO',
    model: 'A98 5G',
    os: 'Android',
    osVersion: '15',
    appVersion: '2.0.16',
    appBuildNumber: '63',
  );
  const tRegistration = SessionRegistration(
    status: SessionRegistrationStatus.registered,
    sessionEpoch: 2,
    activeDeviceId: 'device_1',
  );

  setUpAll(() {
    registerFallbackValue(DeviceRegistrationMode.passiveSync);
    registerFallbackValue(tDeviceInfo);
  });

  setUp(() {
    mockRepository = MockActiveDeviceRepository();
    mockTokenService = MockDeviceTokenService();
    mockCache = MockTokenSyncCache();
    mockAppInfo = MockAppInfoService();
    mockDeviceInfo = MockDeviceInfoService();

    useCase = RegisterActiveDeviceUseCase(
      mockRepository,
      mockTokenService,
      mockCache,
      mockAppInfo,
      mockDeviceInfo,
    );

    when(() => mockTokenService.getToken()).thenAnswer((_) async => tToken);
    when(() => mockDeviceInfo.getDeviceInfo()).thenAnswer((_) async {
      return tDeviceInfo;
    });
    when(() => mockAppInfo.getAppInfo()).thenAnswer(
      (_) async => const AppInfo(
        version: '2.0.16',
        buildNumber: '63',
        appName: 'MeMuslim',
        packageName: 'com.tilawa',
      ),
    );
    when(() => mockCache.saveSync(any(), any())).thenAnswer((_) async {});
    when(() => mockCache.saveSessionEpoch(any())).thenAnswer((_) async {});
    when(() => mockCache.saveActiveDeviceId(any())).thenAnswer((_) async {});
    when(() => mockCache.clearSession()).thenAnswer((_) async {});
  });

  test(
    'explicit sign-in registers with explicit mode and caches session',
    () async {
      when(
        () => mockRepository.registerActiveDevice(
          fcmToken: any(named: 'fcmToken'),
          registrationMode: any(named: 'registrationMode'),
          appVersion: any(named: 'appVersion'),
          deviceInfo: any(named: 'deviceInfo'),
          signOut: any(named: 'signOut'),
        ),
      ).thenAnswer((_) async => const Right(tRegistration));

      final result = await useCase.registerExplicitSignIn(tUserId);

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.registerActiveDevice(
          fcmToken: tToken,
          registrationMode: DeviceRegistrationMode.explicitSignIn,
          appVersion: '2.0.16',
          deviceInfo: tDeviceInfo,
        ),
      ).called(1);
      verify(() => mockCache.saveSessionEpoch(2)).called(1);
      verify(() => mockCache.saveActiveDeviceId('device_1')).called(1);
      verify(() => mockCache.saveSync(tToken, tUserId)).called(1);
    },
  );

  test('passive sync uses passive mode', () async {
    when(
      () => mockRepository.registerActiveDevice(
        fcmToken: any(named: 'fcmToken'),
        registrationMode: any(named: 'registrationMode'),
        appVersion: any(named: 'appVersion'),
        deviceInfo: any(named: 'deviceInfo'),
        signOut: any(named: 'signOut'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        SessionRegistration(
          status: SessionRegistrationStatus.updatedSameDevice,
          sessionEpoch: 5,
          activeDeviceId: 'device_1',
        ),
      ),
    );

    final result = await useCase.syncPassive(tUserId);

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.registerActiveDevice(
        fcmToken: tToken,
        registrationMode: DeviceRegistrationMode.passiveSync,
        appVersion: '2.0.16',
        deviceInfo: tDeviceInfo,
      ),
    ).called(1);
    verify(() => mockCache.saveSessionEpoch(5)).called(1);
  });

  test(
    'passive stale response clears local cache and returns stale failure',
    () async {
      when(
        () => mockRepository.registerActiveDevice(
          fcmToken: any(named: 'fcmToken'),
          registrationMode: any(named: 'registrationMode'),
          appVersion: any(named: 'appVersion'),
          deviceInfo: any(named: 'deviceInfo'),
          signOut: any(named: 'signOut'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          SessionRegistration(
            status: SessionRegistrationStatus.staleDeviceRejected,
            sessionEpoch: 5,
            activeDeviceId: 'device_2',
          ),
        ),
      );

      final result = await useCase.syncPassive(tUserId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, AuthErrorKey.staleDeviceRejected),
        (_) => fail('expected Left'),
      );
      verify(() => mockCache.clearSession()).called(1);
      verifyNever(() => mockCache.saveSessionEpoch(any()));
    },
  );

  test('explicit sign-in still registers when FCM token is missing', () async {
    when(() => mockTokenService.getToken()).thenAnswer((_) async => null);
    when(
      () => mockRepository.registerActiveDevice(
        fcmToken: any(named: 'fcmToken'),
        registrationMode: any(named: 'registrationMode'),
        appVersion: any(named: 'appVersion'),
        deviceInfo: any(named: 'deviceInfo'),
        signOut: any(named: 'signOut'),
      ),
    ).thenAnswer((_) async => const Right(tRegistration));

    final result = await useCase.registerExplicitSignIn(tUserId);

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.registerActiveDevice(
        fcmToken: null,
        registrationMode: DeviceRegistrationMode.explicitSignIn,
        appVersion: '2.0.16',
        deviceInfo: tDeviceInfo,
      ),
    ).called(1);
    verifyNever(() => mockCache.saveSync(any(), any()));
  });

  test('returns failure when repository returns Left', () async {
    when(
      () => mockRepository.registerActiveDevice(
        fcmToken: any(named: 'fcmToken'),
        registrationMode: any(named: 'registrationMode'),
        appVersion: any(named: 'appVersion'),
        deviceInfo: any(named: 'deviceInfo'),
        signOut: any(named: 'signOut'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('boom')),
    );

    final result = await useCase.registerExplicitSignIn(tUserId);

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
    }, (_) => fail('expected Left'));
  });

  test('maps App Check failure key from repository', () async {
    when(
      () => mockRepository.registerActiveDevice(
        fcmToken: any(named: 'fcmToken'),
        registrationMode: any(named: 'registrationMode'),
        appVersion: any(named: 'appVersion'),
        deviceInfo: any(named: 'deviceInfo'),
        signOut: any(named: 'signOut'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(AuthErrorKey.appCheckFailed)),
    );

    final result = await useCase.registerExplicitSignIn(tUserId);

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure.message, AuthErrorKey.appCheckFailed);
    }, (_) => fail('expected Left'));
  });

  test('clearActiveDeviceOnSignOut clears local session cache', () async {
    when(
      () => mockRepository.registerActiveDevice(
        fcmToken: any(named: 'fcmToken'),
        registrationMode: any(named: 'registrationMode'),
        signOut: true,
      ),
    ).thenAnswer(
      (_) async => const Right(
        SessionRegistration(
          status: SessionRegistrationStatus.updatedSameDevice,
          sessionEpoch: 2,
          activeDeviceId: 'device_1',
        ),
      ),
    );

    final result = await useCase.clearActiveDeviceOnSignOut(tUserId);

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.registerActiveDevice(
        fcmToken: '',
        registrationMode: DeviceRegistrationMode.passiveSync,
        signOut: true,
      ),
    ).called(1);
    verify(() => mockCache.clearSession()).called(1);
  });

  test(
    'clearActiveDeviceOnSignOut clears local session when remote fails',
    () async {
      when(
        () => mockRepository.registerActiveDevice(
          fcmToken: any(named: 'fcmToken'),
          registrationMode: any(named: 'registrationMode'),
          signOut: true,
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('network')),
      );

      final result = await useCase.clearActiveDeviceOnSignOut(tUserId);

      expect(result.isRight(), isTrue);
      verify(() => mockCache.clearSession()).called(1);
    },
  );
}
