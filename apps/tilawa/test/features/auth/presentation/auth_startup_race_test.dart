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

/// Splash/startup races: slow Firebase, offline session, first install.
void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late MockStartupNotificationRepository mockNotificationRepository;
  late MockAwaitAuthRestorationUseCase mockAwaitAuthRestoration;
  late MockGetPersistedAuthenticatedUserUseCase mockGetPersistedUser;
  late GetSplashNextRouteUseCase useCase;

  final UserEntity firebaseUser = UserEntity(
    id: '1',
    email: 'a@b.com',
    displayName: 'Test',
    createdAt: DateTime.utc(2024),
  );

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    mockNotificationRepository = MockStartupNotificationRepository();
    mockAwaitAuthRestoration = MockAwaitAuthRestorationUseCase();
    mockGetPersistedUser = MockGetPersistedAuthenticatedUserUseCase();
    useCase = GetSplashNextRouteUseCase(
      mockGetCurrentUserUseCase,
      mockCheckOnboardingStatus,
      mockNotificationRepository,
      mockAwaitAuthRestoration,
      mockGetPersistedUser,
    );
    when(
      () => mockNotificationRepository.consumePendingNotification(),
    ).thenReturn(null);
    when(() => mockGetPersistedUser()).thenAnswer((_) async => null);
    when(() => mockCheckOnboardingStatus()).thenAnswer((_) async => true);
  });

  test('first install routes to login when no user exists anywhere', () async {
    when(() => mockGetCurrentUserUseCase()).thenReturn(null);
    when(
      () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
    ).thenAnswer((_) async => AuthRestorationOutcome.unauthenticated);

    final SplashRouteResult result = await useCase();

    expect(result.destination, SplashDestination.login);
    verify(
      () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
    ).called(1);
  });

  test(
    'slow Firebase restoration still reaches home when user exists after wait',
    () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(firebaseUser);
      when(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return AuthRestorationOutcome.restored;
      });

      final SplashRouteResult result = await useCase();

      expect(result.destination, SplashDestination.home);
      verify(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      ).called(1);
      verify(() => mockGetCurrentUserUseCase()).called(1);
    },
  );

  test(
    'uses persisted session hint when Firebase user is still null after wait',
    () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(null);
      when(
        () => mockGetPersistedUser(),
      ).thenAnswer((_) async => firebaseUser);
      when(
        () => mockAwaitAuthRestoration(sessionUser: firebaseUser),
      ).thenAnswer((_) async => AuthRestorationOutcome.unauthenticated);

      final SplashRouteResult result = await useCase();

      expect(result.destination, SplashDestination.home);
      verify(
        () => mockAwaitAuthRestoration(sessionUser: firebaseUser),
      ).called(1);
    },
  );

  test(
    'offline cold start routes home when persisted session exists',
    () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(null);
      when(
        () => mockGetPersistedUser(),
      ).thenAnswer((_) async => firebaseUser);
      when(
        () => mockAwaitAuthRestoration(sessionUser: firebaseUser),
      ).thenAnswer((_) async {
        // Simulates restoration timeout with no network — no throw.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return AuthRestorationOutcome.pendingUnresolved;
      });

      final SplashRouteResult result = await useCase();

      expect(result.destination, SplashDestination.home);
    },
  );

  test(
    'Firebase user present skips persisted lookup for routing destination',
    () async {
      when(() => mockGetCurrentUserUseCase()).thenReturn(firebaseUser);
      when(
        () => mockAwaitAuthRestoration(sessionUser: any(named: 'sessionUser')),
      ).thenAnswer((_) async => AuthRestorationOutcome.unauthenticated);

      final SplashRouteResult result = await useCase();

      expect(result.destination, SplashDestination.home);
      verify(() => mockGetPersistedUser()).called(1);
    },
  );
}
