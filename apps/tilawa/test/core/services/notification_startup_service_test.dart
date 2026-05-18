import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import 'notification_startup_service_test.mocks.dart';

@GenerateMocks([
  INotificationDispatcher,
  SharedPreferencesAsync,
  ProcessIdProvider,
  NotificationHandlersInitializer,
  IAdhanAlarmPlayer,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockINotificationDispatcher mockDispatcher;
  late MockSharedPreferencesAsync mockPrefs;
  late MockProcessIdProvider mockPid;
  late MockNotificationHandlersInitializer mockInit;
  late MockIAdhanAlarmPlayer mockPlayer;
  late List<({String location, Object? extra})> navCalls;

  NotificationStartupServiceImpl makeService() =>
      NotificationStartupServiceImpl(
        mockDispatcher,
        mockPrefs,
        mockPid,
        mockInit,
        mockPlayer,
        navigator: (location, {extra}) {
          navCalls.add((location: location, extra: extra));
        },
      );

  setUp(() {
    mockDispatcher = MockINotificationDispatcher();
    mockPrefs = MockSharedPreferencesAsync();
    mockPid = MockProcessIdProvider();
    mockInit = MockNotificationHandlersInitializer();
    mockPlayer = MockIAdhanAlarmPlayer();
    navCalls = <({String location, Object? extra})>[];

    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.lastProcessedNotificationId = null;

    when(mockInit()).thenAnswer((_) async {});
    when(mockPid.currentPid).thenReturn(1234);
    when(mockPrefs.getInt(any)).thenAnswer((_) async => null);
    when(mockPrefs.setInt(any, any)).thenAnswer((_) async {});
    when(
      mockDispatcher.initialize(
        createHighImportanceChannel: anyNamed('createHighImportanceChannel'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockDispatcher.getNotificationAppLaunchDetails(),
    ).thenAnswer((_) async => null);
    when(
      mockDispatcher.processLaunchNotification(),
    ).thenAnswer((_) async => false);
    when(mockPlayer.isSupported).thenReturn(true);
    when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    when(mockPlayer.getActiveAdhanPayload()).thenAnswer((_) async => null);
  });

  group('handleAppResume', () {
    test(
      'routes to status screen when adhan is playing with payload',
      () async {
        const String payload = '{"prayer_name":"asr"}';
        when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
        when(
          mockPlayer.getActiveAdhanPayload(),
        ).thenAnswer((_) async => payload);

        final service = makeService();
        await service.handleAppResume();

        expect(navCalls, hasLength(1));
        expect(
          navCalls.single.location,
          const PrayerNotificationStatusRoute().location,
        );
        expect(navCalls.single.extra, payload);
        verify(mockPlayer.isAdhanPlaying()).called(1);
        verify(mockPlayer.getActiveAdhanPayload()).called(1);
      },
    );

    test('does not route when adhan is not playing', () async {
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

      final service = makeService();
      await service.handleAppResume();

      expect(navCalls, isEmpty);
      verifyNever(mockPlayer.getActiveAdhanPayload());
    });

    test('does not route when player is not supported', () async {
      when(mockPlayer.isSupported).thenReturn(false);
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);

      final service = makeService();
      await service.handleAppResume();

      expect(navCalls, isEmpty);
      verifyNever(mockPlayer.isAdhanPlaying());
      verifyNever(mockPlayer.getActiveAdhanPayload());
    });

    test('does not route when payload is null even if playing', () async {
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
      when(mockPlayer.getActiveAdhanPayload()).thenAnswer((_) async => null);

      final service = makeService();
      await service.handleAppResume();

      expect(navCalls, isEmpty);
    });

    test('does not route when payload is empty string', () async {
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
      when(mockPlayer.getActiveAdhanPayload()).thenAnswer((_) async => '');

      final service = makeService();
      await service.handleAppResume();

      expect(navCalls, isEmpty);
    });

    test('swallows errors thrown by the player', () async {
      when(
        mockPlayer.isAdhanPlaying(),
      ).thenAnswer((_) async => throw StateError('boom'));

      final service = makeService();
      await service.handleAppResume();

      expect(navCalls, isEmpty);
    });

    test('skips when _isChecking is already true (re-entry guard)', () async {
      final Completer<void> initGate = Completer<void>();
      when(mockInit()).thenAnswer((_) => initGate.future);

      final service = makeService();

      // Kick off the first call; it parks inside _handlersInitializer.
      final Future<void> first = service.handleAppResume();
      // A second call while the first is mid-flight should bail out early.
      final Future<void> second = service.handleAppResume();

      initGate.complete();
      await Future.wait([first, second]);

      // Init only invoked once because the second call short-circuited.
      verify(mockInit()).called(1);
    });
  });

  group('handleAppStartup', () {
    test(
      'routes to status screen after probe delay when adhan playing',
      () async {
        const String payload = '{"prayer_name":"fajr"}';
        when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
        when(
          mockPlayer.getActiveAdhanPayload(),
        ).thenAnswer((_) async => payload);

        final service = makeService();
        await service.handleAppStartup();
        // Probe delay is 900ms; wait slightly past it to let both timers fire.
        await Future<void>.delayed(const Duration(milliseconds: 1100));

        expect(navCalls, hasLength(1));
        expect(navCalls.single.extra, payload);
      },
    );

    test('does not route on cold start when adhan is not playing', () async {
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

      final service = makeService();
      await service.handleAppStartup();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(navCalls, isEmpty);
    });

    test(
      'skips startup probe when pendingStartupNotificationLaunch is set',
      () async {
        AppRouter.pendingStartupNotificationLaunch = true;
        when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
        when(
          mockPlayer.getActiveAdhanPayload(),
        ).thenAnswer((_) async => '{"x":1}');

        final service = makeService();
        await service.handleAppStartup();
        await Future<void>.delayed(const Duration(milliseconds: 1100));

        // No deferred probe was scheduled; adhan-playing routing is bypassed
        // in favour of the FCM launch path that owns cold-start navigation.
        expect(navCalls, isEmpty);
        verify(mockInit()).called(1);
        expect(AppRouter.pendingStartupNotificationLaunch, isFalse);
      },
    );

    test('handleAppStartup is idempotent across repeat calls', () async {
      when(mockPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
      when(
        mockPlayer.getActiveAdhanPayload(),
      ).thenAnswer((_) async => '{"x":1}');

      final service = makeService();
      await service.handleAppStartup();
      await service.handleAppStartup();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Only one routing call because the second startup short-circuited.
      expect(navCalls, hasLength(1));
    });
  });

  test('dispose cancels pending probe timer', () {
    final service = makeService();
    // Should not throw even when no timer has been scheduled yet.
    service.dispose();
  });
}
