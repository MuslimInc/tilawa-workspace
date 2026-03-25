import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/router/app_router.dart';

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockCheckOnboardingStatus mockCheckOnboardingStatus;
  late GetSplashNextRouteUseCase useCase;

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockCheckOnboardingStatus = MockCheckOnboardingStatus();
    useCase = GetSplashNextRouteUseCase(
      mockGetCurrentUserUseCase,
      mockCheckOnboardingStatus,
    );
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
  });

  tearDown(() {
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
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
        AppRouter.pendingLocalNotificationResponse = response;

        final result = await useCase();

        expect(result.destination, SplashDestination.notificationLaunch);
        expect(result.notificationData, {'type': 'settings'});
        expect(AppRouter.pendingLocalNotificationResponse, isNull);
        verifyNever(() => mockCheckOnboardingStatus.call());
        verifyNever(() => mockGetCurrentUserUseCase.call());
      },
    );

    test(
      'returns notification launch for a pending FCM message and clears it',
      () async {
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
