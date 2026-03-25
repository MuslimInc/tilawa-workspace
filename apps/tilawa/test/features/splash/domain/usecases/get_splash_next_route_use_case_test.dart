import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

class MockNotificationDispatcher extends Mock
    implements INotificationDispatcher {}

void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late MockNotificationDispatcher mockDispatcher;
  late GetSplashNextRouteUseCase useCase;

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    mockDispatcher = MockNotificationDispatcher();
    useCase = GetSplashNextRouteUseCase(
      mockGetCurrentUserUseCase,
      mockCheckOnboardingStatus,
      mockDispatcher,
    );
    AppRouter.pendingFcmMessage = null;
  });

  tearDown(() {
    AppRouter.pendingFcmMessage = null;
  });

  group('GetSplashNextRouteUseCase', () {
    test(
      'returns notification launch for a local notification payload',
      () async {
        const NotificationResponse response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{"type":"settings"}',
        );

        when(() => mockDispatcher.getNotificationAppLaunchDetails()).thenAnswer(
          (_) async => const NotificationAppLaunchDetails(
            true,
            notificationResponse: response,
          ),
        );

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'settings'});
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'returns notification launch for a pending FCM message and clears it',
      () async {
        when(
          () => mockDispatcher.getNotificationAppLaunchDetails(),
        ).thenAnswer((_) async => null);
        AppRouter.pendingFcmMessage = const RemoteMessage(
          data: {'type': 'quran', 'surahNumber': '2'},
        );

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'quran', 'surahNumber': '2'});
        expect(AppRouter.pendingFcmMessage, isNull);
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );
  });
}
