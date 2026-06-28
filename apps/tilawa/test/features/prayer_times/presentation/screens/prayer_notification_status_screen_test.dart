import 'dart:async';
import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_settings_entity.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_notification_status_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/services/prayer_adhan_notification_service_test.mocks.dart';

class _FakeLoadPrayerSettings implements LoadPrayerSettingsUseCase {
  @override
  Future<Either<Failure, PrayerSettingsEntity>> call() async =>
      Left(Failure.unexpectedError('no settings'));
}

void main() {
  late MockIAdhanAlarmPlayer mockAdhanPlayer;

  setUp(() async {
    mockAdhanPlayer = MockIAdhanAlarmPlayer();
    await getIt.reset();
    getIt.registerSingleton<IAdhanAlarmPlayer>(mockAdhanPlayer);
    getIt.registerSingleton<LoadPrayerSettingsUseCase>(
      _FakeLoadPrayerSettings(),
    );

    // Stub default methods
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    when(mockAdhanPlayer.stopCurrentAdhan()).thenAnswer((_) async {});
  });

  Widget createWidget({String? payloadJson}) {
    final screen = PrayerNotificationStatusScreen(payloadJson: payloadJson);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => screen,
        ),
      ],
    );

    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
      routerConfig: router,
    );
  }

  String encodePayload({
    String prayerName = 'Fajr',
    bool adhanEnabled = true,
    String? soundName,
  }) {
    return jsonEncode({
      'prayer_name': prayerName,
      'scheduled_time_ms': DateTime.now().millisecondsSinceEpoch,
      'adhan_enabled': adhanEnabled,
      'sound_name': ?soundName,
    });
  }

  /// Avoids [WidgetTester.pumpAndSettle], which never completes while adhan
  /// playback polling is active (`adhan_enabled: true` in the payload).
  Future<void> pumpStatusScreenReady(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  final String validPayload = encodePayload(soundName: 'adhan_makkah');

  /// Disables periodic polling so playback-probe tests can settle frames.
  final String playbackProbePayload = encodePayload(
    adhanEnabled: false,
    soundName: 'adhan_makkah',
  );

  testWidgets(
    'renders payload content before playback status check completes',
    (tester) async {
      final playbackStatus = Completer<bool>();
      when(
        mockAdhanPlayer.isAdhanPlaying(),
      ).thenAnswer((_) => playbackStatus.future);

      await tester.pumpWidget(createWidget(payloadJson: validPayload));
      await tester.pump();

      expect(find.byType(TilawaLoadingIndicator), findsNothing);
      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Stop Adhan'), findsOneWidget);

      playbackStatus.complete(false);
      await pumpStatusScreenReady(tester);
      expect(find.text('Stop Adhan'), findsNothing);
    },
  );

  testWidgets('renders prayer details and status chips when loaded', (
    tester,
  ) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await pumpStatusScreenReady(tester);

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Adhan'), findsOneWidget);
    expect(find.text('Enabled'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('adhan_makkah'), findsOneWidget);
  });

  testWidgets('accepts local notification payload keys', (tester) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

    final localPayload = jsonEncode({
      'type': 'prayer',
      'prayer': 'isha',
      'scheduled_time_ms': DateTime.now().millisecondsSinceEpoch,
      'adhan_enabled': false,
      'notification_id': 2006,
    });

    await tester.pumpWidget(createWidget(payloadJson: localPayload));
    await pumpStatusScreenReady(tester);

    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('shows Stop button only when Adhan is playing', (tester) async {
    // State 1: Not playing
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    await tester.pumpWidget(
      createWidget(payloadJson: playbackProbePayload),
    );
    await pumpStatusScreenReady(tester);
    expect(find.text('Stop Adhan'), findsNothing);

    // State 2: Playing - use a different key to force BlocProvider re-creation
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
    await tester.pumpWidget(
      Container(
        key: const Key('state_playing'),
        child: createWidget(payloadJson: playbackProbePayload),
      ),
    );
    await pumpStatusScreenReady(tester);

    expect(find.text('Stop Adhan'), findsOneWidget);
  });

  testWidgets('calls stopCurrentAdhan when Stop button is pressed', (
    tester,
  ) async {
    // Set a larger surface size to ensure button is on screen
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
    await tester.pumpWidget(
      createWidget(payloadJson: playbackProbePayload),
    );
    await pumpStatusScreenReady(tester);

    final stopBtn = find.text('Stop Adhan');
    expect(stopBtn, findsOneWidget);

    await tester.tap(stopBtn);
    await pumpStatusScreenReady(tester);

    verify(mockAdhanPlayer.stopCurrentAdhan()).called(1);
  });

  testWidgets('shows error state for invalid payload', (tester) async {
    await tester.pumpWidget(createWidget(payloadJson: 'invalid'));
    await tester.pumpAndSettle();

    expect(find.byType(TilawaEmptyState), findsOneWidget);
    // The title in EmptyState is 'Error'
    expect(find.text('Error'), findsOneWidget);
  });
}
