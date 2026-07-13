import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  late AppStartupTasks startupTasks;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  setUp(() {
    AppRouter.resetForTesting();
    configureAppLaunch(launchConfig: const AppLaunchConfig(hiveInit: true));
    resetMemoizedInitFutures();
    startupTasks = AppStartupTasks(
      launchConfig: const AppLaunchConfig(hiveInit: true),
    );
    startupTasks.resetMemoizedInitFutures();
  });

  tearDown(() async {
    AppRouter.resetForTesting();
    if (Hive.isBoxOpen(TasbeehConstants.storageBoxName)) {
      await Hive.box(TasbeehConstants.storageBoxName).close();
    }
  });

  group('initializeHive', () {
    test('returns immediately when hive init is disabled', () async {
      final AppStartupTasks disabledTasks = AppStartupTasks(
        launchConfig: const AppLaunchConfig(hiveInit: false),
      );

      await disabledTasks.initializeHive();
    });

    test('memoizes concurrent initializeHive calls', () async {
      await Future.wait<void>(<Future<void>>[
        startupTasks.initializeHive(),
        startupTasks.initializeHive(),
        startupTasks.initializeHive(),
      ]);

      final box = await Hive.openBox(TasbeehConstants.storageBoxName);
      expect(box, isNotNull);
    });

    test(
      'ensureHiveInitialized shares the same memoized init future',
      () async {
        await Future.wait<void>(<Future<void>>[
          ensureHiveInitialized(),
          startupTasks.initializeHive(),
        ]);

        final box = await Hive.openBox(TasbeehConstants.storageBoxName);
        expect(box, isNotNull);
      },
    );

    test('initializeHive survives path provider failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              throw PlatformException(code: 'path_provider_failed');
            },
          );
      startupTasks.resetMemoizedInitFutures();
      resetMemoizedInitFutures();

      await expectLater(startupTasks.initializeHive(), completes);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async => '.',
          );
    });
  });

  group('tasbeeh notification cold start', () {
    test('sets tasbeeh route and kicks off hive init', () async {
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '${TasbeehConstants.reminderPayloadPrefix}abc',
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(
        AppRouter.pendingColdStartLocation,
        const TasbeehRoute(dhikrId: 'abc').location,
      );
      expect(AppRouter.pendingLocalNotificationResponse, isNull);

      await startupTasks.initializeHive();
      final box = await Hive.openBox(TasbeehConstants.storageBoxName);
      expect(box, isNotNull);
    });

    test(
      'pending launch without resolvable data flags startup notification',
      () {
        AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'not-json-and-not-tasbeeh',
        );

        startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

        expect(AppRouter.pendingStartupNotificationLaunch, isTrue);
        expect(AppRouter.disableStateRestoration, isTrue);
        expect(AppRouter.pendingColdStartLocation, isNull);
      },
    );

    test('resolves cold start route from pending FCM message', () {
      AppRouter.pendingFcmMessage = const RemoteMessage(
        data: <String, dynamic>{'type': 'settings'},
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(
        AppRouter.pendingColdStartLocation,
        const SettingsRoute().location,
      );
      expect(AppRouter.pendingFcmMessage, isNull);
    });

    test('non-tasbeeh cold start does not require tasbeeh box', () async {
      AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '{"type":"settings"}',
      );

      startupTasks.applyColdStartRouteFromPendingLaunchForTesting();

      expect(
        AppRouter.pendingColdStartLocation,
        const SettingsRoute().location,
      );
    });
  });
}
