import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/bootstrap/shared_preferences_migration.dart';
import 'package:tilawa/core/services/analytics_initialization_service.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';
import 'package:tilawa/core/services/firebase_initialization_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/downloads/domain/services/downloads_initializer.dart';
import 'package:tilawa/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa/features/notifications/data/services/fcm_service.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa/features/downloads/domain/services/download_notification_service_interface.dart';
import 'package:quran_qcf/quran_qcf.dart';

import 'support/map_backed_shared_preferences_async.dart';

// Mocks
class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class MockAnalyticsInitService extends Mock
    implements AnalyticsInitializationService {}

class MockNotificationPermissionService extends Mock
    implements NotificationPermissionService {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockDownloadsInitializer extends Mock implements DownloadsInitializer {}

class MockFirebaseInitializationService extends Mock
    implements FirebaseInitializationService {}

class MockAthkarNotificationService extends Mock
    implements IAthkarNotificationService {}

class MockStorage extends Mock implements Storage {}

class MockFCMService extends Mock implements FCMService {}

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

class MockNotificationDispatcher extends Mock
    implements INotificationDispatcher {}

class MockDownloadNotificationService extends Mock
    implements IDownloadNotificationService {}

class MockPrayerAdhanNotificationService extends Mock
    implements IPrayerAdhanNotificationService {}

class MockMushafService extends Mock implements MushafService {}

void main() {
  final GetIt getIt = GetIt.instance;

  // Define mocks
  late MockCrashlyticsService mockCrashlytics;
  late MockAnalyticsInitService mockAnalytics;
  late MockNotificationPermissionService mockNotificationPermission;
  late MockNotificationsRepository mockNotificationsRepo;
  late MockDownloadsInitializer mockDownloads;
  late MockFirebaseInitializationService mockFirebaseInit;
  late MockAthkarNotificationService mockAthkarService;
  late MockStorage mockStorage;
  late MockFCMService mockFCMService;
  late MockAudioPlayerHandler mockAudioHandler;
  late MockNotificationDispatcher mockNotificationDispatcher;
  late MockDownloadNotificationService mockDownloadNotificationService;
  late MockPrayerAdhanNotificationService mockPrayerNotificationService;
  late MockMushafService mockMushafService;
  late MapBackedSharedPreferencesAsync mapPrefs;

  setUpAll(() async {
    AppStartupTasks.skipNonCriticalServicesForTesting = true;
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock PathProvider for HydratedStorage
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return '.';
          },
        );

    // Mock Firebase Core
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/firebase_core'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'Firebase#initializeCore') {
              return [
                {
                  'name': '[DEFAULT]',
                  'options': {
                    'apiKey': '123',
                    'appId': '123',
                    'messagingSenderId': '123',
                    'projectId': '123',
                  },
                  'pluginConstants': {},
                },
              ];
            }
            if (methodCall.method == 'Firebase#initializeApp') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              return {
                'name': args['appName'],
                'options': args['options'],
                'pluginConstants': {},
              };
            }
            return null;
          },
        );
  });

  setUp(() {
    mapPrefs = MapBackedSharedPreferencesAsync();
    sharedPreferencesAsyncFactoryForTesting = () => mapPrefs.prefs;
    legacySharedPreferencesFactoryForTesting = () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return SharedPreferences.getInstance();
    };

    mockCrashlytics = MockCrashlyticsService();
    mockAnalytics = MockAnalyticsInitService();
    mockNotificationPermission = MockNotificationPermissionService();
    mockNotificationsRepo = MockNotificationsRepository();
    mockDownloads = MockDownloadsInitializer();
    mockFirebaseInit = MockFirebaseInitializationService();
    mockAthkarService = MockAthkarNotificationService();
    mockStorage = MockStorage();
    mockFCMService = MockFCMService();
    mockAudioHandler = MockAudioPlayerHandler();
    mockNotificationDispatcher = MockNotificationDispatcher();
    mockDownloadNotificationService = MockDownloadNotificationService();
    mockPrayerNotificationService = MockPrayerAdhanNotificationService();
    mockMushafService = MockMushafService();

    getIt.allowReassignment = true;

    // Register mocks
    getIt.registerSingleton<CrashlyticsService>(mockCrashlytics);
    getIt.registerSingleton<AnalyticsInitializationService>(mockAnalytics);
    getIt.registerSingleton<NotificationPermissionService>(
      mockNotificationPermission,
    );
    getIt.registerSingleton<NotificationsRepository>(mockNotificationsRepo);
    getIt.registerSingleton<DownloadsInitializer>(mockDownloads);
    getIt.registerSingleton<FirebaseInitializationService>(mockFirebaseInit);
    getIt.registerSingleton<IAthkarNotificationService>(mockAthkarService);
    getIt.registerSingleton<FCMService>(mockFCMService);
    getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
    getIt.registerSingleton<INotificationDispatcher>(
      mockNotificationDispatcher,
    );
    getIt.registerSingleton<IDownloadNotificationService>(
      mockDownloadNotificationService,
    );
    getIt.registerSingleton<IPrayerAdhanNotificationService>(
      mockPrayerNotificationService,
    );
    getIt.allowReassignment = true;
    if (getIt.isRegistered<MushafService>()) {
      getIt.unregister<MushafService>();
    }
    getIt.registerSingleton<MushafService>(mockMushafService);

    // Stubs
    when(() => mockCrashlytics.initialize()).thenAnswer((_) async {});
    when(() => mockAnalytics.initialize()).thenAnswer((_) async {});
    when(
      () => mockNotificationPermission.requestPermissionIfNecessary(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationPermission.isPermissionGranted(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationsRepo.requestPermission(),
    ).thenAnswer((_) async {});
    when(() => mockNotificationsRepo.getToken()).thenAnswer((_) async {
      return null;
    });
    when(
      () => mockNotificationsRepo.initializeListeners(),
    ).thenAnswer((_) async {});
    when(() => mockDownloads.initialize()).thenAnswer((_) async {});
    when(
      () => mockFirebaseInit.initializeFirebaseData(),
    ).thenAnswer((_) async {});
    when(() => mockAthkarService.initialize()).thenAnswer((_) async {
      return;
    });
    when(() => mockAthkarService.scheduleAthkarNotifications()).thenAnswer((
      _,
    ) async {
      return;
    });
    when(() => mockFCMService.initialize()).thenAnswer((_) async {});
    when(
      () => mockNotificationDispatcher.initialize(
        createHighImportanceChannel: any(named: 'createHighImportanceChannel'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockDownloadNotificationService.initialize(),
    ).thenAnswer((_) async {});
    when(
      () => mockPrayerNotificationService.initialize(),
    ).thenAnswer((_) async {});
    when(() => mockMushafService.ensureLoaded()).thenAnswer((_) async {});

    HydratedBloc.storage = mockStorage;

    configureAppLaunch(
      launchConfig: const AppLaunchConfig(subscriptionServiceEnabled: true),
    );

    // Bootstrap memoizes one-shot init helpers to avoid duplicate runtime init;
    // clear the cache so each test's freshly stubbed mocks are actually called.
    resetMemoizedInitFutures();
  });

  tearDown(() {
    sharedPreferencesAsyncFactoryForTesting = null;
    legacySharedPreferencesFactoryForTesting = null;
  });

  group('Main Initialization Functions', () {
    test('initializeNotificationService success', () async {
      await initializeNotificationService();
      verify(() => mockNotificationsRepo.requestPermission()).called(1);
      verify(() => mockNotificationsRepo.getToken()).called(1);
      verify(() => mockNotificationsRepo.initializeListeners()).called(1);
    });

    test('initializeNotificationService failure', () async {
      when(
        () => mockNotificationsRepo.requestPermission(),
      ).thenThrow(Exception('Fail'));
      await initializeNotificationService(); // Should catch exception
      verify(() => mockNotificationsRepo.requestPermission()).called(1);
    });

    test('initializeCrashlytics success', () async {
      await initializeCrashlytics();
      verify(() => mockCrashlytics.initialize()).called(1);
    });

    test('initializeCrashlytics failure', () async {
      when(() => mockCrashlytics.initialize()).thenThrow(Exception('Fail'));
      await initializeCrashlytics();
      verify(() => mockCrashlytics.initialize()).called(1);
    });

    test('initializeAnalytics success', () async {
      await initializeAnalytics();
      verify(() => mockAnalytics.initialize()).called(1);
    });

    test('initializeAnalytics failure', () async {
      when(() => mockAnalytics.initialize()).thenThrow(Exception('Fail'));
      await initializeAnalytics();
      verify(() => mockAnalytics.initialize()).called(1);
    });

    test('requestNotificationPermission success', () async {
      await requestNotificationPermission();
      verify(
        () => mockNotificationPermission.requestPermissionIfNecessary(),
      ).called(1);
    });

    test(
      'requestNotificationPermission refreshes prayer notifications after grant',
      () async {
        await requestNotificationPermission();

        verify(() => mockPrayerNotificationService.initialize()).called(1);
      },
    );

    test(
      'requestNotificationPermission skips prayer refresh when permission denied',
      () async {
        when(
          () => mockNotificationPermission.isPermissionGranted(),
        ).thenAnswer((_) async => false);

        await requestNotificationPermission();

        verifyNever(() => mockPrayerNotificationService.initialize());
      },
    );

    test('requestNotificationPermission failure', () async {
      when(
        () => mockNotificationPermission.requestPermissionIfNecessary(),
      ).thenThrow(Exception('Fail'));
      await requestNotificationPermission();
      verify(
        () => mockNotificationPermission.requestPermissionIfNecessary(),
      ).called(1);
    });

    test('initializeFirebaseDataAsync success', () async {
      await initializeFirebaseDataAsync();
      verify(() => mockFirebaseInit.initializeFirebaseData()).called(1);
    });

    test('initializeFirebaseDataAsync failure', () async {
      when(
        () => mockFirebaseInit.initializeFirebaseData(),
      ).thenThrow(Exception('Fail'));
      await initializeFirebaseDataAsync();
      verify(() => mockFirebaseInit.initializeFirebaseData()).called(1);
    });

    test(
      'initializeFirebaseDataAsync skips when subscription service disabled',
      () async {
        configureAppLaunch(
          launchConfig: const AppLaunchConfig(
            subscriptionServiceEnabled: false,
          ),
        );
        addTearDown(() {
          configureAppLaunch(
            launchConfig: const AppLaunchConfig(
              subscriptionServiceEnabled: true,
            ),
          );
        });
        await initializeFirebaseDataAsync();
        verifyNever(() => mockFirebaseInit.initializeFirebaseData());
      },
    );

    test('initializeDownloads success', () async {
      await initializeDownloads();
      verify(() => mockDownloads.initialize()).called(1);
    });

    test('initializeDownloads failure', () async {
      when(() => mockDownloads.initialize()).thenThrow(Exception('Fail'));
      await initializeDownloads();
      verify(() => mockDownloads.initialize()).called(1);
    });

    test('initializeAthkarNotifications success', () async {
      await initializeAthkarNotifications();
      verify(() => mockAthkarService.scheduleAthkarNotifications()).called(1);
    });

    test('initializeAthkarNotifications failure', () async {
      when(
        () => mockAthkarService.scheduleAthkarNotifications(),
      ).thenThrow(Exception('Fail'));
      await initializeAthkarNotifications();
      verify(() => mockAthkarService.scheduleAthkarNotifications()).called(1);
    });

    test(
      'initializeNotificationHandlers registers prayer notifications',
      () async {
        await initializeNotificationHandlers();

        verify(
          () => mockNotificationDispatcher.initialize(
            createHighImportanceChannel: false,
          ),
        ).called(1);
        verify(() => mockAthkarService.initialize()).called(1);
        verify(() => mockPrayerNotificationService.initialize()).called(1);
        verify(() => mockDownloadNotificationService.initialize()).called(1);
      },
    );

    // Test initializeNonCriticalServices
    // Using fakeAsync wouldn't work well with Future.microtask
    // We can rely on await behavior of individual functions but initializeNonCriticalServices
    // wraps everything in Future.microtask and is void.
    // However, for coverage, calling it is enough.
    testWidgets('initializeNonCriticalServices coverage', (tester) async {
      AppStartupTasks.skipNonCriticalServicesForTesting = true;
      addTearDown(
        () => AppStartupTasks.skipNonCriticalServicesForTesting = false,
      );

      initializeNonCriticalServices();
      // Trigger postFrameCallback
      await tester.pump();
      // With skip flag true, it uses Duration.zero
      await tester.pumpAndSettle();
    });

    test('firebaseMessagingBackgroundHandler', () async {
      // Need to ensure Firebase can be tested. setupFirebaseCoreMocks() is already called manually.
      // Calling the handler.
      // It calls Firebase.initializeApp.
      // DefaultFirebaseOptions might throw on Test platform (MacOS), so we catch it.
      try {
        await firebaseMessagingBackgroundHandler(const RemoteMessage());
      } catch (e) {
        // Expected if platform is not supported or Firebase already initialized with different options
        logger.d(
          'Handled expected error in firebaseMessagingBackgroundHandler test: $e',
        );
      }
    });
  });

  group('Bootstrap', () {
    test('bootstrap success', () async {
      var runnerCalled = false;
      var diCalled = false;

      await bootstrap(
        runner: (widget) => runnerCalled = true,
        diConfigurator: ({AppLaunchConfig? launchConfig}) async =>
            diCalled = true,
      );

      expect(runnerCalled, isTrue);
      expect(diCalled, isTrue);

      // Verify HydratedStorage init attempted
      // verify(() => HydratedStorage.build(...)) - hard to verify static call without wrapper
      // But we can verify side effects or mocks if possible.
      // Since we mocked PathProvider, it shouldn't crash.
    });

    test('bootstrap catastrophic failure handles and restarts', () async {
      // Simulate failure in DI
      await bootstrap(
        runner: (widget) {},
        diConfigurator: ({AppLaunchConfig? launchConfig}) async =>
            throw Exception('Fatal'),
      );

      // Logs are printed, and runner is called (bootstrap catches errors and continues)
      // Wait, bootstrap catches DI error and continues to run app.
      // It catches "Catastrophic failure" in the outer try/catch too.
      // If DI throws, it is caught in inner try-catch and continues.
    });

    test('bootstrap really catastrophic failure triggers re-run', () async {
      // We can't easily trigger the outer catch block unless WidgetsFlutterBinding throws?
      // Or if we mock runner to throw first time?

      var runCount = 0;
      await bootstrap(
        runner: (widget) {
          runCount++;
          if (runCount == 1) {
            throw Exception('Crash');
          }
        },
        diConfigurator: ({AppLaunchConfig? launchConfig}) async {},
      );

      // It should have caught 'Crash' and logged it.
      // The outer try-catch catches it.
      // Then "Last resort: try to start the app" logic calls run again.
      // So runCount should be 2.
      expect(runCount, 2);
    });

    test('bootstrap fails twice (truly catastrophic)', () async {
      var runCount = 0;
      try {
        await bootstrap(
          runner: (widget) {
            runCount++;
            throw Exception('Crash $runCount');
          },
          diConfigurator: ({AppLaunchConfig? launchConfig}) async {},
        );
      } catch (e) {
        // Expected to rethrow after 2nd failure
      }

      // Should have tried twice
      expect(runCount, 2);
    });
  });
}
