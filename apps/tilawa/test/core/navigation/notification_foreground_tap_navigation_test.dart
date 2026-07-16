import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/navigation/notification_launch_dedup.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/athkar_notification_service.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_foreground_tap_navigation_test.mocks.dart';

@GenerateMocks([
  SharedPreferencesAsync,
  AnalyticsService,
  IAdhanAlarmPlayer,
  NotificationPermissionService,
  ProcessIdProvider,
  NotificationHandlersInitializer,
  INotificationDispatcher,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int morningAthkarId = 1001;
  const String morningAthkarPayload = 'morning_athkar_foreground_test';

  late NotificationDispatcher dispatcher;
  late MockSharedPreferencesAsync mockPrefs;
  late MockAnalyticsService mockAnalytics;
  late RecordingNavigationService navigationService;
  late AthkarNotificationService athkarService;

  NotificationResponse morningAthkarTap() {
    return const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      id: morningAthkarId,
      payload: morningAthkarPayload,
    );
  }

  void startOnNonTargetRoute() {
    AppRouter.resetForTesting();
    AppRouter.init();
    navigationService.clear();
    AppRouter.router.go(const HomeRoute().location);
  }

  void registerAthkarHandler() {
    dispatcher.registerPayloadHandler(
      serviceId: 'athkar',
      matcher: (String? payload) =>
          payload?.startsWith('morning_athkar_') ?? false,
      handler: athkarService.handleNotificationResponse,
    );
  }

  setUp(() {
    dispatcher = NotificationDispatcher();
    mockPrefs = MockSharedPreferencesAsync();
    mockAnalytics = MockAnalyticsService();
    navigationService = RecordingNavigationService();

    when(mockPrefs.getString(any)).thenAnswer((_) async => null);
    when(mockPrefs.getInt(any)).thenAnswer((_) async => null);
    when(mockPrefs.setString(any, any)).thenAnswer((_) async {
      return;
    });
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {
      return;
    });
    when(
      mockAnalytics.logAthkarNotificationOpen(any, any),
    ).thenAnswer((_) async {
      return;
    });
    when(
      mockAnalytics.logEvent(any, parameters: anyNamed('parameters')),
    ).thenAnswer((_) async {
      return;
    });

    athkarService = AthkarNotificationService(
      mockPrefs,
      dispatcher,
      mockAnalytics,
      navigationService,
      FakePrayerTimesRepository(),
    );
  });

  tearDown(AppRouter.resetForTesting);

  group('NotificationDispatcher foreground tap routing', () {
    test('returns false when no handlers are registered', () async {
      final bool routed = await dispatcher.routeNotificationForTest(
        morningAthkarTap(),
      );
      expect(routed, isFalse);
    });

    test('routes athkar when handler is registered', () async {
      registerAthkarHandler();

      final bool routed = await dispatcher.routeNotificationForTest(
        morningAthkarTap(),
      );

      expect(routed, isTrue);
      verify(
        mockAnalytics.logAthkarNotificationOpen(
          DeepLinkResolver.athkarMorningCategoryId,
          DeepLinkResolver.athkarMorningCategoryName,
        ),
      ).called(1);
    });

    test(
      'debug lab id inside download range routes athkar not downloads',
      () async {
        registerAthkarHandler();
        dispatcher.registerIdRangeHandler(
          serviceId: 'downloads',
          minIdInclusive: 100000,
          maxIdExclusive: 1000000,
          handler: (_) async {},
        );

        final bool routed = await dispatcher.routeNotificationForTest(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 900001,
            payload: 'morning_athkar_debug_lab',
          ),
        );

        expect(routed, isTrue);
        verify(
          mockAnalytics.logAthkarNotificationOpen(
            DeepLinkResolver.athkarMorningCategoryId,
            DeepLinkResolver.athkarMorningCategoryName,
          ),
        ).called(1);
      },
    );
  });

  group('NotificationStartupService handler registration', () {
    late MockINotificationDispatcher mockDispatcher;
    late MockSharedPreferencesAsync mockStartupPrefs;
    late MockNotificationHandlersInitializer mockHandlersInit;
    late MockIAdhanAlarmPlayer mockAdhanPlayer;
    late MockProcessIdProvider mockPid;

    setUp(() {
      mockDispatcher = MockINotificationDispatcher();
      mockStartupPrefs = MockSharedPreferencesAsync();
      mockHandlersInit = MockNotificationHandlersInitializer();
      mockAdhanPlayer = MockIAdhanAlarmPlayer();
      mockPid = MockProcessIdProvider();

      when(mockHandlersInit()).thenAnswer((_) async {});
      when(mockPid.currentPid).thenReturn(4242);
      when(mockStartupPrefs.getInt(any)).thenAnswer((_) async => null);
      when(mockStartupPrefs.getString(any)).thenAnswer((_) async => null);
      when(mockStartupPrefs.setInt(any, any)).thenAnswer((_) async {
        return;
      });
      when(mockStartupPrefs.setString(any, any)).thenAnswer((_) async {
        return;
      });
      when(
        mockDispatcher.initialize(
          createHighImportanceChannel: anyNamed('createHighImportanceChannel'),
        ),
      ).thenAnswer((_) async {
        return;
      });
      when(
        mockDispatcher.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);
      when(mockAdhanPlayer.isSupported).thenReturn(false);
    });

    test('handleAppStartup registers handlers on normal launch', () async {
      final NotificationStartupServiceImpl service =
          NotificationStartupServiceImpl(
            mockDispatcher,
            mockStartupPrefs,
            mockPid,
            mockHandlersInit,
            mockAdhanPlayer,
          );

      await service.handleAppStartup();

      verify(mockHandlersInit()).called(1);
    });
  });

  group('Foreground notification tap navigation', () {
    test('home → athkar tap navigates away from home', () async {
      startOnNonTargetRoute();
      registerAthkarHandler();

      final bool routed = await dispatcher.routeNotificationForTest(
        morningAthkarTap(),
      );

      expect(routed, isTrue);
      expect(navigationService.calls, hasLength(1));
      expect(navigationService.calls.single.location, contains('/athkar'));
    });

    test('home → prayer payload-only tap navigates to prayer status', () async {
      startOnNonTargetRoute();

      final MockIAdhanAlarmPlayer mockAdhanPlayer = MockIAdhanAlarmPlayer();
      final MockNotificationPermissionService mockPermissions =
          MockNotificationPermissionService();
      when(mockAdhanPlayer.onNotificationTapped).thenAnswer(
        (_) => const Stream<String>.empty(),
      );
      when(
        mockAdhanPlayer.pullPendingNotificationTapPayload(),
      ).thenAnswer((_) async => null);
      when(mockAdhanPlayer.isSupported).thenReturn(false);

      final PrayerAdhanNotificationService prayerService =
          PrayerAdhanNotificationService(
            mockPrefs,
            dispatcher,
            navigationService,
            mockAnalytics,
            mockAdhanPlayer,
            mockPermissions,
          );
      dispatcher.registerPayloadHandler(
        serviceId: 'prayer_notifications',
        matcher: prayerService.isPrayerPayload,
        handler: prayerService.handleNotificationResponse,
      );

      final String payload = jsonEncode({
        PrayerNotificationConfig.payloadTypeKey:
            PrayerNotificationConfig.payloadTypeValue,
        PrayerNotificationConfig.payloadPrayerKey: 'fajr',
        'prayer_name': 'fajr',
        'prayer_key': 'fajr',
        'is_adhan_playing': true,
      });

      final bool routed = await dispatcher.routeNotificationForTest(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ),
      );

      expect(routed, isTrue);
      expect(navigationService.calls, hasLength(1));
      expect(
        navigationService.calls.single.location,
        const PrayerNotificationStatusRoute().location,
      );
    });

    test('settings payload while on home navigates to settings', () async {
      startOnNonTargetRoute();

      dispatcher.registerPayloadHandler(
        serviceId: 'fcm_service',
        matcher: (String? payload) {
          if (payload == null) {
            return false;
          }
          try {
            final dynamic decoded = jsonDecode(payload);
            return decoded is Map && decoded['type'] == 'settings';
          } catch (_) {
            return false;
          }
        },
        handler: (NotificationResponse response) async {
          navigationService.navigateToNotification(
            const SettingsRoute().location,
          );
        },
      );

      await dispatcher.routeNotificationForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 42,
          payload: '{"type":"settings"}',
        ),
      );

      expect(navigationService.calls, hasLength(1));
      expect(navigationService.calls.single.location, '/settings');
    });

    test('invalid payload does not navigate to athkar', () async {
      startOnNonTargetRoute();
      registerAthkarHandler();

      await dispatcher.routeNotificationForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 999,
          payload: 'not-json-and-not-athkar',
        ),
      );

      expect(navigationService.calls, isEmpty);
    });

    test('same notification tapped twice routes handler only once', () async {
      startOnNonTargetRoute();

      var handlerCalls = 0;
      dispatcher.registerPayloadHandler(
        serviceId: 'athkar',
        matcher: (String? payload) =>
            payload?.startsWith('morning_athkar_') ?? false,
        handler: (NotificationResponse response) async {
          handlerCalls++;
          await athkarService.handleNotificationResponse(response);
        },
      );

      final NotificationResponse tap = morningAthkarTap();
      expect(await dispatcher.routeNotificationForTest(tap), isTrue);
      expect(await dispatcher.routeNotificationForTest(tap), isTrue);

      expect(handlerCalls, 1);
      expect(navigationService.calls, hasLength(1));
    });

    test('foreground tap persists launch dedup signature', () async {
      final GetIt container = getIt;
      if (container.isRegistered<SharedPreferencesAsync>()) {
        await container.unregister<SharedPreferencesAsync>();
      }
      if (container.isRegistered<ProcessIdProvider>()) {
        await container.unregister<ProcessIdProvider>();
      }
      container.registerSingleton<SharedPreferencesAsync>(mockPrefs);
      container.registerSingleton<ProcessIdProvider>(const ProcessIdProvider());

      startOnNonTargetRoute();
      registerAthkarHandler();

      await dispatcher.routeNotificationForTest(morningAthkarTap());

      verify(
        mockPrefs.setString(
          NotificationLaunchDedup.lastNotifPayloadSigKey,
          'p:$morningAthkarPayload',
        ),
      ).called(1);

      await container.unregister<SharedPreferencesAsync>();
      await container.unregister<ProcessIdProvider>();
    });

    test(
      'stored foreground tap signature blocks hot-restart replay probe',
      () async {
        const int pid = 7777;
        when(
          mockPrefs.getInt(NotificationLaunchDedup.lastNotifPidKey),
        ).thenAnswer((_) async => pid);
        when(
          mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
        ).thenAnswer((_) async => 'p:$morningAthkarPayload');

        final bool replay = await NotificationLaunchDedup.isProcessedLaunch(
          launchNotificationId: morningAthkarId,
          launchPayload: morningAthkarPayload,
          prefs: mockPrefs,
          pid: pid,
        );

        expect(replay, isTrue);
      },
    );

    test('different notification after prior tap still navigates', () async {
      startOnNonTargetRoute();
      registerAthkarHandler();
      dispatcher.registerPayloadHandler(
        serviceId: 'athkar_evening',
        matcher: (String? payload) =>
            payload?.startsWith('evening_athkar_') ?? false,
        handler: (NotificationResponse response) async {
          navigationService.navigateToNotification(
            AthkarDetailsRoute(
              categoryId: DeepLinkResolver.athkarEveningCategoryId,
              categoryName: DeepLinkResolver.athkarEveningCategoryName,
              source: NavigationSource.notification.wireValue,
            ).location,
          );
        },
      );

      await dispatcher.routeNotificationForTest(morningAthkarTap());
      expect(navigationService.calls, hasLength(1));
      expect(navigationService.calls.single.location, contains('/athkar'));

      navigationService.clear();
      AppRouter.router.go(const HomeRoute().location);

      await dispatcher.routeNotificationForTest(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1002,
          payload: 'evening_athkar_foreground_test',
        ),
      );

      expect(navigationService.calls, hasLength(1));
      expect(navigationService.calls.single.location, contains('/athkar'));
    });
  });
}

class RecordingNavigationService implements NavigationService {
  RecordingNavigationService() : _delegate = NavigationServiceImpl();

  final NavigationServiceImpl _delegate;
  final List<({String location, Object? extra})> calls =
      <({String location, Object? extra})>[];

  void clear() => calls.clear();

  @override
  Future<void> push(String location, {Object? extra}) {
    return _delegate.push(location, extra: extra);
  }

  @override
  void navigateToNotification(String location, {Object? extra}) {
    calls.add((location: location, extra: extra));
    _delegate.navigateToNotification(location, extra: extra);
  }

  @override
  void routeToDestination(NotificationDestination destination) {
    calls.add((location: destination.location, extra: destination.extra));
    _delegate.routeToDestination(destination);
  }

  @override
  String? getCurrentLocation() => _delegate.getCurrentLocation();
}

class FakePrayerTimesRepository implements PrayerTimesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
