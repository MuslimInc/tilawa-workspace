import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/navigation/notification_launch_dedup.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_action_catalog.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_constants.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_dedup_snapshot.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_lab_screen.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_lab_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_lab_tile.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_log_store.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'notification_debug_lab_test.mocks.dart';

@GenerateMocks([
  NavigationService,
  INotificationDispatcher,
  ProcessIdProvider,
  SharedPreferencesAsync,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int pid = 4242;
  late MockSharedPreferencesAsync mockPrefs;
  late MockProcessIdProvider pidProvider;
  late Map<String, Object> prefStore;

  Future<void> pumpDebugLab(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    TextDirection? textDirection,
    Size surfaceSize = const Size(360, 800),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: textDirection == null
            ? child
            : Directionality(textDirection: textDirection, child: child),
      ),
    );
    await tester.pump();
  }

  Future<void> registerDebugLabDeps() async {
    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerSingleton<SharedPreferencesAsync>(mockPrefs);
    getIt.registerSingleton<ProcessIdProvider>(pidProvider);
    getIt.registerSingleton<INotificationDispatcher>(
      MockINotificationDispatcher(),
    );
    getIt.registerSingleton<NavigationService>(MockNavigationService());
    getIt.registerSingleton<NotificationDebugLogStore>(
      NotificationDebugLogStore(),
    );
    getIt.registerSingleton<NotificationDebugLabService>(
      NotificationDebugLabService(
        getIt<INotificationDispatcher>(),
        mockPrefs,
        pidProvider,
        getIt<NavigationService>(),
        getIt<NotificationDebugLogStore>(),
      ),
    );
  }

  void stubEmptyPrefs() {
    prefStore = <String, Object>{};
    when(mockPrefs.getInt(any)).thenAnswer((Invocation inv) async {
      return prefStore[inv.positionalArguments[0] as String] as int?;
    });
    when(mockPrefs.getString(any)).thenAnswer((Invocation inv) async {
      return prefStore[inv.positionalArguments[0] as String] as String?;
    });
    when(mockPrefs.setInt(any, any)).thenAnswer((Invocation inv) async {
      prefStore[inv.positionalArguments[0] as String] =
          inv.positionalArguments[1] as int;
    });
    when(mockPrefs.setString(any, any)).thenAnswer((Invocation inv) async {
      prefStore[inv.positionalArguments[0] as String] =
          inv.positionalArguments[1] as String;
    });
    when(mockPrefs.remove(any)).thenAnswer((Invocation inv) async {
      prefStore.remove(inv.positionalArguments[0] as String);
    });
  }

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    pidProvider = MockProcessIdProvider();
    when(pidProvider.currentPid).thenReturn(pid);
    stubEmptyPrefs();
    AppRouter.resetForTesting();
  });

  tearDown(() async {
    AppRouter.resetForTesting();
    if (GetIt.I.isRegistered<NotificationDebugLogStore>()) {
      await getIt.reset();
    }
  });

  group('NotificationDebugActionCatalog', () {
    test('launch simulation catalog builds', () {
      final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        NotificationDebugActionCatalog.launchSimulationActions(l10n),
        hasLength(7),
      );
    });
  });

  group('NotificationDebugLabTile', () {
    testWidgets('shows localized title in debug builds', (tester) async {
      await pumpDebugLab(
        tester,
        const Scaffold(body: NotificationDebugLabTile()),
      );
      expect(find.text('Notification Debug Lab'), findsOneWidget);
    });

    testWidgets('shows Arabic title in RTL locale', (tester) async {
      await pumpDebugLab(
        tester,
        const Scaffold(body: NotificationDebugLabTile()),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );
      expect(find.text('اختبار الإشعارات'), findsOneWidget);
    });
  });

  group('NotificationDebugLabScreen', () {
    testWidgets('renders main sections', (tester) async {
      await registerDebugLabDeps();
      await pumpDebugLab(tester, const NotificationDebugLabScreen());
      await tester.pump();
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, -2400));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('notification_debug_local_section')),
        findsOneWidget,
      );
      expect(find.text('schedule_morning_athkar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notification_debug_launch_section')),
        findsOneWidget,
      );
      expect(find.text('simulate_athkar_launch'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notification_debug_dedup_section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification_debug_logs_section')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('360x800 viewport does not overflow', (tester) async {
      await registerDebugLabDeps();
      await pumpDebugLab(
        tester,
        const NotificationDebugLabScreen(),
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL layout does not overflow', (tester) async {
      await registerDebugLabDeps();
      await pumpDebugLab(
        tester,
        const NotificationDebugLabScreen(),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clear dedup removes persisted keys', (tester) async {
      prefStore[NotificationLaunchDedup.lastNotifPidKey] = pid;
      prefStore[NotificationLaunchDedup.lastNotifIdKey] = 900001;
      prefStore[NotificationLaunchDedup.lastNotifPayloadSigKey] = 'p:test';
      await registerDebugLabDeps();
      await pumpDebugLab(tester, const NotificationDebugLabScreen());
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notification_debug_clear_dedup')),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(
        find.byKey(const ValueKey('notification_debug_clear_dedup')),
      );
      await tester.pump();

      verify(
        mockPrefs.remove(NotificationLaunchDedup.lastNotifIdKey),
      ).called(1);
      verify(
        mockPrefs.remove(NotificationLaunchDedup.lastNotifPidKey),
      ).called(1);
      verify(
        mockPrefs.remove(NotificationLaunchDedup.lastNotifPayloadSigKey),
      ).called(1);
      verify(
        mockPrefs.remove(NotificationLaunchDedup.schemaVersionKey),
      ).called(1);
      expect(
        prefStore.containsKey(NotificationLaunchDedup.lastNotifPidKey),
        isFalse,
      );
    });
  });

  group('payload resolution preview', () {
    test('invalid payload does not resolve to Athkar', () {
      final Map<String, dynamic>? data =
          NotificationNavigationResolver.notificationDataFromPayload(
            NotificationDebugConstants.invalidPayloadValue(),
          );
      expect(data, isNull);
    });

    test('Athkar payload resolves to Athkar details route', () {
      final Map<String, dynamic>? data =
          NotificationNavigationResolver.notificationDataFromPayload(
            NotificationDebugConstants.morningAthkarPayload(),
          );
      expect(data, isNotNull);
      final String route = NotificationNavigationResolver.resolveLocation(
        data!,
      );
      expect(
        route,
        startsWith('/athkar/${DeepLinkResolver.athkarMorningCategoryId}'),
      );
    });

    test('Settings payload resolves to Settings', () {
      final Map<String, dynamic>? data =
          NotificationNavigationResolver.notificationDataFromPayload(
            NotificationDebugConstants.settingsPayload(),
          );
      expect(data, isNotNull);
      expect(
        NotificationNavigationResolver.resolveLocation(data!),
        const SettingsRoute().location,
      );
    });
  });

  group('NotificationDebugLabService signatures', () {
    late NotificationDebugLabService service;

    setUp(() async {
      await registerDebugLabDeps();
      service = getIt<NotificationDebugLabService>();
    });

    test('previewSignature id + payload prefers payload', () {
      expect(
        service.previewSignature(
          notificationId: 900001,
          payload: 'morning_athkar_debug_lab',
        ),
        'p:morning_athkar_debug_lab',
      );
    });

    test('previewSignature payload only', () {
      expect(
        service.previewSignature(payload: '{"type":"prayer"}'),
        'p:{"type":"prayer"}',
      );
    });

    test('previewSignature id only', () {
      expect(service.previewSignature(notificationId: 900003), 'i:900003');
    });

    test('previewSignature empty payload', () {
      expect(
        service.previewSignature(notificationId: 900011, payload: ''),
        'i:900011',
      );
    });

    test('same id + same payload + same pid is processed', () async {
      await service.markProcessed(
        NotificationDebugActionSpec(
          key: 'x',
          notificationId: 900013,
          payload: NotificationDebugConstants.morningAthkarPayload(
            suffix: 'same_sig',
          ),
          expectedRoute: '/',
          expectedBehavior: '',
          mechanism: NotificationDebugMechanism.dedupOnly,
        ),
      );
      final NotificationDebugDedupSnapshot snapshot = await service
          .readSnapshot(
            previewNotificationId: 900013,
            previewPayload: NotificationDebugConstants.morningAthkarPayload(
              suffix: 'same_sig',
            ),
          );
      expect(snapshot.isProcessedPreview, isTrue);
    });

    test('same id + different payload is fresh', () async {
      await service.markProcessed(
        NotificationDebugActionSpec(
          key: 'x',
          notificationId: 900014,
          payload: NotificationDebugConstants.morningAthkarPayload(
            suffix: 'variant_a',
          ),
          expectedRoute: '/',
          expectedBehavior: '',
          mechanism: NotificationDebugMechanism.dedupOnly,
        ),
      );
      final NotificationDebugDedupSnapshot snapshot = await service
          .readSnapshot(
            previewNotificationId: 900014,
            previewPayload: NotificationDebugConstants.morningAthkarPayload(
              suffix: 'variant_b',
            ),
          );
      expect(snapshot.isProcessedPreview, isFalse);
    });

    test('payload-only native prayer launch persists signature', () async {
      await service.markProcessed(
        NotificationDebugActionSpec(
          key: 'prayer_payload_only',
          notificationId: null,
          payload: NotificationDebugConstants.prayerPayload(),
          expectedRoute: '/',
          expectedBehavior: '',
          mechanism: NotificationDebugMechanism.dedupOnly,
        ),
      );
      final NotificationDebugDedupSnapshot snapshot = await service
          .readSnapshot(
            previewNotificationId: null,
            previewPayload: NotificationDebugConstants.prayerPayload(),
          );
      expect(snapshot.storedPayloadSignature, startsWith('p:'));
      expect(snapshot.isProcessedPreview, isTrue);
    });
  });
}
