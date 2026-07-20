import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/splash/domain/repositories/startup_notification_repository.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_event.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_state.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'adhan_notification_launch_navigation_test.mocks.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream<UserEntity?>.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareGoogleSignIn() async {}

  @override
  Future<AuthResult> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AuthResult> signInWithApple() => throw UnimplementedError();

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> hasAdminClaim() async => false;
}

class _NullGetPersistedAuthenticatedUserUseCase
    implements GetPersistedAuthenticatedUserUseCase {
  const _NullGetPersistedAuthenticatedUserUseCase();

  @override
  Future<UserEntity?> call() async => null;
}

/// Regression tests for the cold-start adhan notification navigation race:
///
/// 1. User taps the native adhan notification → prayer status screen
/// 2. Splash finishes → home / reciters (overwrites step 1)
/// 3. App resume → prayer status again
///
/// These tests encode the *correct* single-destination behavior. They fail on
/// the unfixed codebase and pass once the navigation coordination fix lands.
@GenerateMocks([
  INotificationDispatcher,
  FlutterLocalNotificationsPlugin,
  SharedPreferencesAsync,
  NavigationService,
  AnalyticsService,
  NotificationPermissionService,
  IAdhanAlarmPlayer,
  ProcessIdProvider,
  NotificationHandlersInitializer,
  GetSplashNextRouteUseCase,
  PrepareGoogleSignInUseCase,
  AppStartupReadiness,
  GetCurrentUserUseCase,
  CheckOnboardingStatus,
  StartupNotificationRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockINotificationDispatcher mockDispatcher;
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockSharedPreferencesAsync mockPrefs;
  late MockNavigationService mockNav;
  late MockAnalyticsService mockAnalytics;
  late MockIAdhanAlarmPlayer mockAdhanPlayer;
  late MockNotificationPermissionService mockNotificationPermissions;
  late PrayerAdhanNotificationService prayerService;

  late MockGetSplashNextRouteUseCase mockGetSplashNextRoute;
  late MockPrepareGoogleSignInUseCase mockPrepareGoogleSignIn;
  late MockAppStartupReadiness mockReadiness;
  late SplashBloc splashBloc;

  late List<({String location, Object? extra})> notificationNavigations;

  final String nativeAdhanPayload = jsonEncode({
    'type': 'prayer',
    'prayer': 'fajr',
    'prayer_name': 'fajr',
    'prayer_key': 'fajr',
    'scheduled_time_ms': DateTime.now().millisecondsSinceEpoch,
    'is_adhan_playing': true,
    'adhan_enabled': true,
  });

  void stubPrayerServiceDefaults() {
    when(mockDispatcher.notificationsPlugin).thenReturn(mockPlugin);
    when(
      mockDispatcher.initialize(
        createHighImportanceChannel: anyNamed('createHighImportanceChannel'),
      ),
    ).thenAnswer((_) async {
      return;
    });
    when(
      mockDispatcher.registerHandler(
        serviceId: anyNamed('serviceId'),
        notificationIds: anyNamed('notificationIds'),
        handler: anyNamed('handler'),
      ),
    ).thenReturn(null);
    when(
      mockDispatcher.registerPayloadHandler(
        serviceId: anyNamed('serviceId'),
        matcher: anyNamed('matcher'),
        handler: anyNamed('handler'),
      ),
    ).thenReturn(null);
    when(
      mockAdhanPlayer.onNotificationTapped,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAdhanPlayer.pullPendingNotificationTapPayload(),
    ).thenAnswer((_) async => null);
    when(mockAdhanPlayer.isSupported).thenReturn(false);
    when(mockAdhanPlayer.cancelAllAdhans()).thenAnswer((_) async {
      return;
    });
    when(
      mockNotificationPermissions.isPermissionGranted(),
    ).thenAnswer((_) async => true);
    when(
      mockAnalytics.logEvent(any, parameters: anyNamed('parameters')),
    ).thenAnswer((_) async {
      return;
    });
    when(mockPrefs.getString(any)).thenAnswer((_) async => null);
    when(mockPrefs.setString(any, any)).thenAnswer((_) async {
      return;
    });
    when(mockPrefs.remove(any)).thenAnswer((_) async {
      return;
    });
    when(mockPrefs.getInt(any)).thenAnswer((_) async => null);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
      return;
    });
    when(
      mockPlugin.zonedSchedule(
        id: anyNamed('id'),
        title: anyNamed('title'),
        body: anyNamed('body'),
        scheduledDate: anyNamed('scheduledDate'),
        notificationDetails: anyNamed('notificationDetails'),
        androidScheduleMode: anyNamed('androidScheduleMode'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        payload: anyNamed('payload'),
      ),
    ).thenAnswer((_) async {
      return;
    });
    when(mockPlugin.cancel(id: anyNamed('id'))).thenAnswer((_) async {
      return;
    });
    when(
      mockNav.navigateToNotification(any, extra: anyNamed('extra')),
    ).thenAnswer((invocation) {
      notificationNavigations.add((
        location: invocation.positionalArguments[0] as String,
        extra: invocation.namedArguments[#extra],
      ));
    });
    when(mockNav.getCurrentLocation()).thenReturn(null);
  }

  setUp(() {
    AppRouter.resetForTesting();
    notificationNavigations = <({String location, Object? extra})>[];

    mockDispatcher = MockINotificationDispatcher();
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockPrefs = MockSharedPreferencesAsync();
    mockNav = MockNavigationService();
    mockAnalytics = MockAnalyticsService();
    mockAdhanPlayer = MockIAdhanAlarmPlayer();
    mockNotificationPermissions = MockNotificationPermissionService();

    mockGetSplashNextRoute = MockGetSplashNextRouteUseCase();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    mockReadiness = MockAppStartupReadiness();

    stubPrayerServiceDefaults();

    prayerService = PrayerAdhanNotificationService(
      mockPrefs,
      mockDispatcher,
      mockNav,
      mockAnalytics,
      mockAdhanPlayer,
      mockNotificationPermissions,
    );

    when(mockPrepareGoogleSignIn.call()).thenAnswer((_) async {
      return;
    });
    when(
      mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
    ).thenAnswer((_) async {
      return;
    });
    when(mockReadiness.timedOut).thenReturn(false);
    when(mockReadiness.recitersDataReady).thenReturn(false);

    splashBloc = SplashBloc(
      mockGetSplashNextRoute,
      mockPrepareGoogleSignIn,
      mockReadiness,
    );
  });

  tearDown(() {
    splashBloc.close();
    AppRouter.resetForTesting();
  });

  group(
    'regression: adhan tap during cold start (reported triple navigation)',
    () {
      test(
        'step 1 — native tap while splash is active defers navigation',
        () async {
          when(
            mockNav.getCurrentLocation(),
          ).thenReturn(const SplashRoute().location);

          await prayerService.initialize();
          await prayerService.handleNotificationResponse(
            NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              payload: nativeAdhanPayload,
            ),
          );

          expect(
            notificationNavigations,
            isEmpty,
            reason:
                'Tapping adhan during splash must not navigate immediately; '
                'that is the first leg of the reported prayer→home→prayer race',
          );
          expect(
            AppRouter.pendingColdStartLocation,
            const PrayerNotificationStatusRoute().location,
          );
          expect(AppRouter.pendingColdStartExtra, nativeAdhanPayload);
        },
      );

      test(
        'step 2 — splash must open prayer status when cold start was queued',
        () async {
          AppRouter.setPendingColdStartRoute(
            const PrayerNotificationStatusRoute().location,
            extra: nativeAdhanPayload,
          );
          when(
            mockGetSplashNextRoute.call(),
          ).thenAnswer(
            (_) async => const SplashRouteResult(SplashDestination.home),
          );

          splashBloc.add(const SplashStarted());
          await expectLater(
            splashBloc.stream,
            emits(
              isA<SplashNavigateToNotification>().having(
                (SplashNavigateToNotification state) => state.location,
                'location',
                const PrayerNotificationStatusRoute().location,
              ),
            ),
          );
        },
      );

      test(
        'step 2b — getSplashNextRoute honors pending native adhan cold start',
        () async {
          AppRouter.setPendingColdStartRoute(
            const PrayerNotificationStatusRoute().location,
            extra: nativeAdhanPayload,
          );

          final mockGetCurrentUser = MockGetCurrentUserUseCase();
          final mockCheckOnboarding = MockCheckOnboardingStatus();
          final mockNotificationRepository =
              MockStartupNotificationRepository();
          when(mockCheckOnboarding.call()).thenAnswer((_) async => true);
          when(mockGetCurrentUser.call()).thenReturn(
            UserEntity(
              id: '1',
              email: 'a@b.com',
              displayName: 'Test',
              createdAt: DateTime(2026),
            ),
          );
          when(
            mockNotificationRepository.consumePendingNotification(),
          ).thenReturn(
            Map<String, dynamic>.from(jsonDecode(nativeAdhanPayload) as Map),
          );

          final useCase = GetSplashNextRouteUseCase(
            mockGetCurrentUser,
            mockCheckOnboarding,
            mockNotificationRepository,
            AwaitAuthRestorationUseCase(_FakeAuthRepository()),
            const _NullGetPersistedAuthenticatedUserUseCase(),
          );

          final result = await useCase();

          expect(result.destination, SplashDestination.notificationLaunch);
          expect(result.notificationData?['prayer_key'], 'fajr');
        },
      );

      test(
        'step 3 — resume must not re-navigate when already on prayer status',
        () async {
          AppRouter.isOnPrayerNotificationStatusRouteOverride = () => true;

          when(mockAdhanPlayer.isSupported).thenReturn(true);
          when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
          when(
            mockAdhanPlayer.getActiveAdhanPayload(),
          ).thenAnswer((_) async => nativeAdhanPayload);

          final resumeDispatcher = MockINotificationDispatcher();
          final resumeHandlersInit = MockNotificationHandlersInitializer();
          when(resumeHandlersInit()).thenAnswer((_) async {});
          when(
            resumeDispatcher.getNotificationAppLaunchDetails(),
          ).thenAnswer((_) async => null);

          final resumeNavigations = <({String location, Object? extra})>[];
          final service = NotificationStartupServiceImpl(
            resumeDispatcher,
            MockSharedPreferencesAsync(),
            MockProcessIdProvider(),
            resumeHandlersInit,
            mockAdhanPlayer,
            navigator: (location, {extra}) {
              resumeNavigations.add((location: location, extra: extra));
            },
          );

          await service.handleAppResume();

          expect(
            resumeNavigations,
            isEmpty,
            reason:
                'Resume adhan probe must not push prayer status again when user '
                'is already there (third leg of the reported race)',
          );
        },
      );

      test(
        'full sequence — no eager navigation during splash and no resume redirect',
        () async {
          when(
            mockNav.getCurrentLocation(),
          ).thenReturn(const SplashRoute().location);

          await prayerService.initialize();
          await prayerService.handleNotificationResponse(
            NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              payload: nativeAdhanPayload,
            ),
          );

          expect(notificationNavigations, isEmpty);

          AppRouter.setPendingColdStartRoute(
            const PrayerNotificationStatusRoute().location,
            extra: nativeAdhanPayload,
          );

          when(
            mockGetSplashNextRoute.call(),
          ).thenAnswer(
            (_) async => const SplashRouteResult(SplashDestination.home),
          );

          splashBloc.add(const SplashStarted());
          final SplashState splashOutcome = await splashBloc.stream.firstWhere(
            (SplashState state) => state is! SplashLoading,
          );
          expect(splashOutcome, isA<SplashNavigateToNotification>());

          AppRouter.init();
          AppRouter.router.go(
            const PrayerNotificationStatusRoute().location,
            extra: nativeAdhanPayload,
          );

          when(mockAdhanPlayer.isSupported).thenReturn(true);
          when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
          when(
            mockAdhanPlayer.getActiveAdhanPayload(),
          ).thenAnswer((_) async => nativeAdhanPayload);

          final resumeDispatcher = MockINotificationDispatcher();
          final resumeHandlersInit = MockNotificationHandlersInitializer();
          when(resumeHandlersInit()).thenAnswer((_) async {});
          when(
            resumeDispatcher.getNotificationAppLaunchDetails(),
          ).thenAnswer((_) async => null);

          final resumeNavigations = <({String location, Object? extra})>[];
          final resumeService = NotificationStartupServiceImpl(
            resumeDispatcher,
            MockSharedPreferencesAsync(),
            MockProcessIdProvider(),
            resumeHandlersInit,
            mockAdhanPlayer,
            navigator: (location, {extra}) {
              resumeNavigations.add((location: location, extra: extra));
            },
          );
          await resumeService.handleAppResume();

          expect(resumeNavigations, isEmpty);
        },
      );
    },
  );
}
