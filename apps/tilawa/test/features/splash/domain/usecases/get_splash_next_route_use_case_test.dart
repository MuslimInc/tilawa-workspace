import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/domain/repositories/startup_notification_repository.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

class MockStartupNotificationRepository extends Mock
    implements StartupNotificationRepository {}

void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late MockStartupNotificationRepository mockNotificationRepository;
  late GetSplashNextRouteUseCase useCase;

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    mockNotificationRepository = MockStartupNotificationRepository();
    useCase = GetSplashNextRouteUseCase(
      mockGetCurrentUserUseCase,
      mockCheckOnboardingStatus,
      mockNotificationRepository,
    );
    when(
      () => mockNotificationRepository.consumePendingNotification(),
    ).thenReturn(null);
  });

  group('GetSplashNextRouteUseCase', () {
    test(
      'returns notification launch for a local notification payload',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'settings'});

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'settings'});
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'returns notification launch for a pending FCM message',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'quran', 'surahNumber': '2'});

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'quran', 'surahNumber': '2'});
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test('returns home when signed in and no notification pending', () async {
      when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => true);
      when(() => mockGetCurrentUserUseCase()).thenReturn(
        UserEntity(
          id: '1',
          email: 'a@b.com',
          displayName: 'Test',
          createdAt: DateTime.now(),
        ),
      );

      final result = await useCase();

      expect(result.destination, SplashDestination.home);
      expect(result.notificationData, isNull);
    });

    test(
      'returns notification launch for pending native adhan cold start',
      () async {
        const String payload =
            '{"type":"prayer","prayer_key":"fajr","is_adhan_playing":true}';
        AppRouter.setPendingColdStartRoute(
          const PrayerNotificationStatusRoute().location,
          extra: payload,
        );

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData?['prayer_key'], 'fajr');
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'local notification takes priority over signed-in home routing',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'settings'});

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'falls back to notificationLaunch with null data when payload is unparseable',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn(const {});

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, isNull);
        verifyNever(() => mockCheckOnboardingStatus.call());
      },
    );

    test('returns login when onboarding done but not signed in', () async {
      when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => true);
      when(() => mockGetCurrentUserUseCase()).thenReturn(null);

      final result = await useCase();

      expect(result.destination, SplashDestination.login);
    });

    test('returns onboarding when not yet completed', () async {
      when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => false);

      final result = await useCase();

      expect(result.destination, SplashDestination.onboarding);
      verifyNever(() => mockGetCurrentUserUseCase.call());
    });
  });
}
