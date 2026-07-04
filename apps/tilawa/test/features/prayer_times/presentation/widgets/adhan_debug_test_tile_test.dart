import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/adhan_debug_test_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows localized debug action', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        permissionService: _FakeNotificationPermissionService(),
        prayerNotificationService: _FakePrayerAdhanNotificationService(),
      ),
    );

    expect(find.text('Test Adhan in 10 seconds'), findsOneWidget);
    expect(
      find.text(
        'Requests notification permission, then schedules the native Adhan alarm.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('is hidden when debug gate is off', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        permissionService: _FakeNotificationPermissionService(),
        prayerNotificationService: _FakePrayerAdhanNotificationService(),
        debugMode: false,
      ),
    );

    expect(find.text('Test Adhan in 10 seconds'), findsNothing);
  });

  testWidgets('Arabic RTL layout supports large text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildHarness(
        permissionService: _FakeNotificationPermissionService(),
        prayerNotificationService: _FakePrayerAdhanNotificationService(),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textScaler: const TextScaler.linear(1.4),
      ),
    );

    expect(find.text('اختبار الأذان بعد 10 ثوانٍ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap requests notification permission and schedules adhan', (
    tester,
  ) async {
    final permissionService = _FakeNotificationPermissionService();
    final prayerNotificationService = _FakePrayerAdhanNotificationService();

    await tester.pumpWidget(
      _buildHarness(
        permissionService: permissionService,
        prayerNotificationService: prayerNotificationService,
      ),
    );

    await tester.tap(find.text('Test Adhan in 10 seconds'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(permissionService.requestPermissionCalls, 1);
    expect(permissionService.permissionChecks, 1);
    expect(prayerNotificationService.debugScheduleCalls, 1);
    expect(
      find.text('Adhan test scheduled for 10 seconds from now'),
      findsOneWidget,
    );
  });

  testWidgets('does not schedule adhan when notification permission is denied', (
    tester,
  ) async {
    final permissionService = _FakeNotificationPermissionService(
      permissionGranted: false,
    );
    final prayerNotificationService = _FakePrayerAdhanNotificationService();

    await tester.pumpWidget(
      _buildHarness(
        permissionService: permissionService,
        prayerNotificationService: prayerNotificationService,
      ),
    );

    await tester.tap(find.text('Test Adhan in 10 seconds'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(permissionService.requestPermissionCalls, 1);
    expect(permissionService.permissionChecks, 1);
    expect(prayerNotificationService.debugScheduleCalls, 0);
    expect(
      find.text(
        'Notification permission is required before scheduling the Adhan test',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows loading state and ignores repeat taps', (tester) async {
    final completer = Completer<void>();
    final prayerNotificationService = _FakePrayerAdhanNotificationService(
      debugScheduleCompleter: completer,
    );

    await tester.pumpWidget(
      _buildHarness(
        permissionService: _FakeNotificationPermissionService(),
        prayerNotificationService: prayerNotificationService,
      ),
    );

    await tester.tap(find.text('Test Adhan in 10 seconds'));
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);

    await tester.tap(find.text('Test Adhan in 10 seconds'));
    await tester.pump();

    expect(prayerNotificationService.debugScheduleCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });
}

Widget _buildHarness({
  required NotificationPermissionService permissionService,
  required IPrayerAdhanNotificationService prayerNotificationService,
  bool debugMode = true,
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    builder: (context, child) {
      Widget wrapped = TilawaFeedbackHost(child: child!);
      final scaler = textScaler;
      if (scaler != null) {
        wrapped = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: wrapped,
        );
      }
      return wrapped;
    },
    home: _OptionalDirectionality(
      textDirection: textDirection,
      body: AdhanDebugTestTile(
        debugMode: debugMode,
        notificationPermissionService: permissionService,
        prayerNotificationService: prayerNotificationService,
      ),
    ),
  );
}

class _OptionalDirectionality extends StatelessWidget {
  const _OptionalDirectionality({
    required this.body,
    required this.textDirection,
  });

  final Widget body;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(body: body);
    final direction = textDirection;
    if (direction == null) {
      return scaffold;
    }
    return Directionality(textDirection: direction, child: scaffold);
  }
}

class _FakeNotificationPermissionService
    implements NotificationPermissionService {
  _FakeNotificationPermissionService({this.permissionGranted = true});

  bool permissionGranted;
  int requestPermissionCalls = 0;
  int permissionChecks = 0;

  @override
  Future<bool> hasRequestedPermission() async => false;

  @override
  Future<bool> isFirstLaunch() async => false;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<bool> isPermissionGranted() async {
    permissionChecks++;
    return permissionGranted;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<void> requestPermissionIfNecessary() async {}
}

class _FakePrayerAdhanNotificationService
    implements IPrayerAdhanNotificationService {
  _FakePrayerAdhanNotificationService({this.debugScheduleCompleter});

  final Completer<void>? debugScheduleCompleter;
  int debugScheduleCalls = 0;

  @override
  Future<void> cancelAllPrayerNotifications() async {}

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> debugScheduleTestAdhan() {
    debugScheduleCalls++;
    return debugScheduleCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<void> fireTestNotification({
    required PrayerType prayer,
    required bool playAdhan,
  }) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  }) async {}
}
