import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_launch_dedup.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import 'notification_hot_restart_navigation_test.mocks.dart';

@GenerateMocks([
  INotificationDispatcher,
  SharedPreferencesAsync,
  ProcessIdProvider,
  NotificationHandlersInitializer,
  IAdhanAlarmPlayer,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int morningAthkarNotificationId = 1001;
  const String morningAthkarPayload = 'morning_athkar_20260627120000';
  const int processPid = 4242;

  late MockINotificationDispatcher mockDispatcher;
  late MockSharedPreferencesAsync mockPrefs;
  late MockProcessIdProvider mockPid;
  late AppStartupTasks startupTasks;

  final String morningAthkarLocation = AthkarDetailsRoute(
    categoryId: DeepLinkResolver.athkarMorningCategoryId,
    categoryName: DeepLinkResolver.athkarMorningCategoryName,
    source: NavigationSource.notification.wireValue,
  ).location;

  final String settingsLocation = const SettingsRoute().location;

  NotificationAppLaunchDetails launchDetails({
    required int? id,
    required String? payload,
  }) {
    return NotificationAppLaunchDetails(
      true,
      notificationResponse: NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: id,
        payload: payload,
      ),
    );
  }

  Future<void> registerProbeDependencies() async {
    final GetIt container = getIt;
    if (container.isRegistered<INotificationDispatcher>()) {
      await container.unregister<INotificationDispatcher>();
    }
    if (container.isRegistered<SharedPreferencesAsync>()) {
      await container.unregister<SharedPreferencesAsync>();
    }
    if (container.isRegistered<ProcessIdProvider>()) {
      await container.unregister<ProcessIdProvider>();
    }
    container.registerSingleton<INotificationDispatcher>(mockDispatcher);
    container.registerSingleton<SharedPreferencesAsync>(mockPrefs);
    container.registerSingleton<ProcessIdProvider>(mockPid);
  }

  void stubPrefsForStoredLaunch({
    required int storedPid,
    required String payloadSig,
    int? storedId,
  }) {
    when(
      mockPrefs.getInt(NotificationLaunchDedup.lastNotifPidKey),
    ).thenAnswer((_) async => storedPid);
    when(
      mockPrefs.getString(NotificationLaunchDedup.lastNotifPayloadSigKey),
    ).thenAnswer((_) async => payloadSig);
    when(
      mockPrefs.getInt(NotificationLaunchDedup.lastNotifIdKey),
    ).thenAnswer((_) async => storedId);
  }

  void stubLaunchProbe({required NotificationAppLaunchDetails? details}) {
    when(
      mockDispatcher.initialize(createHighImportanceChannel: false),
    ).thenAnswer((_) async {});
    when(
      mockDispatcher.getNotificationAppLaunchDetails(),
    ).thenAnswer((_) async => details);
  }

  setUp(() async {
    AppRouter.resetForTesting();
    mockDispatcher = MockINotificationDispatcher();
    mockPrefs = MockSharedPreferencesAsync();
    mockPid = MockProcessIdProvider();
    startupTasks = AppStartupTasks(
      launchConfig: const AppLaunchConfig(notificationLaunchProbe: true),
    );
    startupTasks.resetMemoizedInitFutures();

    when(mockPid.currentPid).thenReturn(processPid);
    when(mockPrefs.getInt(any)).thenAnswer((_) async => null);
    when(mockPrefs.getString(any)).thenAnswer((_) async => null);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {});
    when(mockPrefs.setString(any, any)).thenAnswer((_) async {});

    await registerProbeDependencies();
  });

  tearDown(() async {
    AppRouter.resetForTesting();
    final GetIt container = getIt;
    if (container.isRegistered<INotificationDispatcher>()) {
      await container.unregister<INotificationDispatcher>();
    }
    if (container.isRegistered<SharedPreferencesAsync>()) {
      await container.unregister<SharedPreferencesAsync>();
    }
    if (container.isRegistered<ProcessIdProvider>()) {
      await container.unregister<ProcessIdProvider>();
    }
  });

  group('platform-agnostic launch replay guard', () {
    test(
      'persisted payload blocks replay after static reset (iOS/Android path)',
      () async {
        stubLaunchProbe(
          details: launchDetails(
            id: morningAthkarNotificationId,
            payload: morningAthkarPayload,
          ),
        );

        await AppRouter.persistProcessedNotificationLaunch(
          notificationId: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        );
        AppRouter.resetForTesting();

        stubPrefsForStoredLaunch(
          storedPid: processPid,
          payloadSig: 'p:$morningAthkarPayload',
          storedId: morningAthkarNotificationId,
        );

        final NotificationResponse? relaunched = await startupTasks
            .probeLocalNotificationLaunchResponseForTesting();

        expect(relaunched, isNull);
      },
    );

    test('payload-only native prayer tap persists and blocks replay', () async {
      const String prayerPayload = '{"type":"prayer","prayer_key":"fajr"}';
      stubLaunchProbe(
        details: launchDetails(id: null, payload: prayerPayload),
      );

      await AppRouter.persistProcessedNotificationLaunch(
        payload: prayerPayload,
      );
      AppRouter.resetForTesting();

      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$prayerPayload',
      );

      final NotificationResponse? relaunched = await startupTasks
          .probeLocalNotificationLaunchResponseForTesting();

      expect(relaunched, isNull);
    });
  });

  group('cold start vs hot restart', () {
    test('same id + same pid after persist does not replay', () async {
      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        ),
      );
      await AppRouter.persistProcessedNotificationLaunch(
        notificationId: morningAthkarNotificationId,
        payload: morningAthkarPayload,
      );
      AppRouter.resetForTesting();
      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      expect(
        await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
        isNull,
      );
    });

    test('same id + different pid allows legitimate cold start', () async {
      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        ),
      );
      stubPrefsForStoredLaunch(
        storedPid: processPid + 1,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      final NotificationResponse? relaunched = await startupTasks
          .probeLocalNotificationLaunchResponseForTesting();

      expect(relaunched, isNotNull);
      expect(relaunched!.id, morningAthkarNotificationId);
    });

    test('different id + same pid navigates as fresh', () async {
      stubLaunchProbe(
        details: launchDetails(
          id: 1002,
          payload: 'evening_athkar_20260627120000',
        ),
      );
      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      final NotificationResponse? relaunched = await startupTasks
          .probeLocalNotificationLaunchResponseForTesting();

      expect(relaunched?.id, 1002);
    });

    test('same id + different payload in same pid is fresh', () async {
      const String newerPayload = 'morning_athkar_20260628120000';
      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: newerPayload,
        ),
      );
      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      final NotificationResponse? relaunched = await startupTasks
          .probeLocalNotificationLaunchResponseForTesting();

      expect(relaunched?.payload, newerPayload);
    });

    test(
      'legacy id-only cache is repaired and blocks hot restart replay',
      () async {
        stubLaunchProbe(
          details: launchDetails(
            id: morningAthkarNotificationId,
            payload: morningAthkarPayload,
          ),
        );
        stubPrefsForStoredLaunch(
          storedPid: processPid,
          payloadSig: 'i:$morningAthkarNotificationId',
          storedId: morningAthkarNotificationId,
        );

        expect(
          await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
          isNull,
        );

        verify(
          mockPrefs.setString(
            NotificationLaunchDedup.lastNotifPayloadSigKey,
            'p:$morningAthkarPayload',
          ),
        ).called(1);
      },
    );
  });

  group('Athkar fallback guard', () {
    test('no launch details does not queue Athkar cold start', () async {
      stubLaunchProbe(details: null);

      expect(
        await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
        isNull,
      );
      expect(AppRouter.pendingColdStartLocation, isNull);
    });

    test('invalid payload flags startup without Athkar route', () {
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'not-json-and-not-tasbeeh',
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(AppRouter.pendingColdStartLocation, isNull);
      expect(AppRouter.pendingStartupNotificationLaunch, isTrue);
    });

    test('settings payload resolves to settings not Athkar', () {
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 55,
        payload: '{"type":"settings"}',
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(AppRouter.pendingColdStartLocation, settingsLocation);
      expect(AppRouter.pendingColdStartLocation, isNot(morningAthkarLocation));
    });

    test('processed Athkar payload does not replay from probe', () async {
      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        ),
      );
      await AppRouter.persistProcessedNotificationLaunch(
        notificationId: morningAthkarNotificationId,
        payload: morningAthkarPayload,
      );
      AppRouter.resetForTesting();
      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      expect(
        await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
        isNull,
      );
      expect(AppRouter.pendingColdStartLocation, isNull);
    });

    test('fresh valid Athkar payload resolves once during bootstrap', () {
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: morningAthkarNotificationId,
        payload: morningAthkarPayload,
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(AppRouter.pendingColdStartLocation, morningAthkarLocation);
    });
  });

  group('router consume safety', () {
    test(
      'consume uses bootstrap payload when pending response was cleared',
      () async {
        AppRouter.setPendingColdStartRoute(morningAthkarLocation);
        AppRouter.lastProcessedNotificationId = morningAthkarNotificationId;
        AppRouter.lastProcessedNotificationPayload = morningAthkarPayload;

        AppRouter.consumePendingNotificationLaunchState();
        await Future<void>.delayed(Duration.zero);

        expect(AppRouter.lastProcessedNotificationPayload, isNull);
        verify(
          mockPrefs.setString(
            NotificationLaunchDedup.lastNotifPayloadSigKey,
            'p:$morningAthkarPayload',
          ),
        ).called(1);
        verifyNever(
          mockPrefs.setString(
            NotificationLaunchDedup.lastNotifPayloadSigKey,
            'i:$morningAthkarNotificationId',
          ),
        );
      },
    );

    test(
      'consume after bootstrap persist keeps payload signature for hot restart',
      () async {
        stubLaunchProbe(
          details: launchDetails(
            id: morningAthkarNotificationId,
            payload: morningAthkarPayload,
          ),
        );

        await AppRouter.persistProcessedNotificationLaunch(
          notificationId: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        );
        AppRouter.setPendingColdStartRoute(morningAthkarLocation);
        AppRouter.lastProcessedNotificationId = morningAthkarNotificationId;
        AppRouter.lastProcessedNotificationPayload = morningAthkarPayload;

        AppRouter.consumePendingNotificationLaunchState();
        AppRouter.resetForTesting();

        stubPrefsForStoredLaunch(
          storedPid: processPid,
          payloadSig: 'p:$morningAthkarPayload',
          storedId: morningAthkarNotificationId,
        );

        expect(
          await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
          isNull,
        );
        expect(AppRouter.pendingColdStartLocation, isNull);
      },
    );

    test('consumePendingNotificationLaunchState is idempotent', () {
      AppRouter.setPendingColdStartRoute(morningAthkarLocation);
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: morningAthkarNotificationId,
        payload: morningAthkarPayload,
      );

      AppRouter.consumePendingNotificationLaunchState();
      AppRouter.consumePendingNotificationLaunchState();

      expect(AppRouter.pendingColdStartLocation, isNull);
      expect(AppRouter.pendingLocalNotificationResponse, isNull);
      expect(AppRouter.pendingStartupNotificationLaunch, isFalse);
    });

    test('double consume still leaves probe stale after persist', () async {
      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        ),
      );

      AppRouter.setPendingColdStartRoute(morningAthkarLocation);
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: morningAthkarNotificationId,
        payload: morningAthkarPayload,
      );
      AppRouter.consumePendingNotificationLaunchState();
      AppRouter.consumePendingNotificationLaunchState();
      AppRouter.resetForTesting();

      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );

      expect(
        await startupTasks.probeLocalNotificationLaunchResponseForTesting(),
        isNull,
      );
    });
  });

  group('deferred startup probe', () {
    test('already handled launch skips processLaunchNotification', () async {
      final MockNotificationHandlersInitializer mockInit =
          MockNotificationHandlersInitializer();
      final MockIAdhanAlarmPlayer mockAdhanPlayer = MockIAdhanAlarmPlayer();
      when(mockInit()).thenAnswer((_) async {});
      when(mockAdhanPlayer.isSupported).thenReturn(false);
      when(
        mockDispatcher.processLaunchNotification(),
      ).thenAnswer((_) async => false);

      stubLaunchProbe(
        details: launchDetails(
          id: morningAthkarNotificationId,
          payload: morningAthkarPayload,
        ),
      );
      stubPrefsForStoredLaunch(
        storedPid: processPid,
        payloadSig: 'p:$morningAthkarPayload',
        storedId: morningAthkarNotificationId,
      );
      AppRouter.lastProcessedNotificationId = morningAthkarNotificationId;

      final NotificationStartupServiceImpl service =
          NotificationStartupServiceImpl(
            mockDispatcher,
            mockPrefs,
            mockPid,
            mockInit,
            mockAdhanPlayer,
            navigator: (_, {extra}) {},
          );

      await service.handleAppStartup();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      verifyNever(mockDispatcher.processLaunchNotification());
    });
  });
}
