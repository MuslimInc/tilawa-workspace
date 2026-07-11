import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/domain/repositories/startup_notification_repository.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

class MockStartupNotificationRepository extends Mock
    implements StartupNotificationRepository {}

class MockAwaitAuthRestorationUseCase extends Mock
    implements AwaitAuthRestorationUseCase {}

class MockGetPersistedAuthenticatedUserUseCase extends Mock
    implements GetPersistedAuthenticatedUserUseCase {}

void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late MockStartupNotificationRepository mockNotificationRepository;
  late MockAwaitAuthRestorationUseCase mockAwaitAuthRestoration;
  late MockGetPersistedAuthenticatedUserUseCase
  mockGetPersistedAuthenticatedUser;
  late GetSplashNextRouteUseCase useCase;

  final UserEntity signedInUser = UserEntity(
    id: '1',
    email: 'a@b.com',
    displayName: 'Test',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    mockNotificationRepository = MockStartupNotificationRepository();
    mockAwaitAuthRestoration = MockAwaitAuthRestorationUseCase();
    mockGetPersistedAuthenticatedUser =
        MockGetPersistedAuthenticatedUserUseCase();
    useCase = GetSplashNextRouteUseCase(
      mockGetCurrentUserUseCase,
      mockCheckOnboardingStatus,
      mockNotificationRepository,
      mockAwaitAuthRestoration,
      mockGetPersistedAuthenticatedUser,
    );
    when(
      () => mockNotificationRepository.consumePendingNotification(),
    ).thenReturn(null);
    when(
      () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
    ).thenAnswer((_) async => AuthRestorationOutcome.unauthenticated);
    when(
      () => mockGetPersistedAuthenticatedUser(),
    ).thenAnswer((_) async => null);
    when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => true);
  });

  group('GetSplashNextRouteUseCase', () {
    test(
      'returns notification launch for signed-in user with local payload',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'settings'});
        when(() => mockGetCurrentUserUseCase()).thenReturn(signedInUser);

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'settings'});
        verify(
          () =>
              mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
        ).called(1);
        verify(() => mockGetCurrentUserUseCase()).called(1);
      },
    );

    test(
      'returns notification launch for signed-in user with FCM payload',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'quran', 'surahNumber': '2'});
        when(() => mockGetCurrentUserUseCase()).thenReturn(signedInUser);

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'quran', 'surahNumber': '2'});
        verify(
          () =>
              mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
        ).called(1);
      },
    );

    test('returns home when signed in and no notification pending', () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(signedInUser);

      final result = await useCase();

      expect(result.destination, SplashDestination.home);
      expect(result.notificationData, isNull);
      verify(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      ).called(1);
    });

    test(
      'returns login when signed out with pending notification payload',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({
          'type': 'prayer',
          'prayer_key': 'fajr',
          'is_adhan_playing': true,
        });
        when(() => mockGetCurrentUserUseCase()).thenReturn(null);

        final result = await useCase();

        expect(result.destination, SplashDestination.login);
        verify(
          () =>
              mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
        ).called(1);
      },
    );

    test(
      'returns login when signed out with local notification payload',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn({'type': 'settings'});
        when(() => mockGetCurrentUserUseCase()).thenReturn(null);

        final result = await useCase();

        expect(result.destination, SplashDestination.login);
        verify(
          () =>
              mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
        ).called(1);
        verify(() => mockCheckOnboardingStatus()).called(1);
      },
    );

    test(
      'falls back to notificationLaunch with null data when payload is empty',
      () async {
        when(
          () => mockNotificationRepository.consumePendingNotification(),
        ).thenReturn(const {});
        when(() => mockGetCurrentUserUseCase()).thenReturn(signedInUser);

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, isNull);
        verify(
          () =>
              mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
        ).called(1);
      },
    );

    test('returns login when onboarding done but not signed in', () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(null);

      final result = await useCase();

      expect(result.destination, SplashDestination.login);
      verify(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      ).called(1);
    });

    test(
      'returns home when Firebase user is missing but persisted session exists',
      () async {
        when(() => mockGetCurrentUserUseCase()).thenReturn(null);
        when(
          () => mockGetPersistedAuthenticatedUser(),
        ).thenAnswer((_) async => signedInUser);

        final result = await useCase();

        expect(result.destination, SplashDestination.home);
        verify(
          () => mockAwaitAuthRestoration(sessionUser: signedInUser),
        ).called(1);
      },
    );

    test('returns onboarding when not yet completed', () async {
      when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => false);

      final result = await useCase();

      expect(result.destination, SplashDestination.onboarding);
      verifyNever(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      );
      verifyNever(() => mockGetCurrentUserUseCase.call());
      verifyNever(
        () => mockNotificationRepository.consumePendingNotification(),
      );
    });

    test(
      'defers notification consume until onboarding is complete',
      () async {
        when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => false);

        await useCase();

        verifyNever(
          () => mockNotificationRepository.consumePendingNotification(),
        );
      },
    );
  });
}
