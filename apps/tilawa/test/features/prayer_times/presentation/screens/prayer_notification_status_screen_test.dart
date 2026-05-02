import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/presentation/screens/prayer_notification_status_screen.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../../../core/services/prayer_adhan_notification_service_test.mocks.dart';

void main() {
  late MockIAdhanAlarmPlayer mockAdhanPlayer;

  setUp(() async {
    mockAdhanPlayer = MockIAdhanAlarmPlayer();
    await getIt.reset();
    getIt.registerSingleton<IAdhanAlarmPlayer>(mockAdhanPlayer);

    // Stub default methods
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    when(mockAdhanPlayer.stopCurrentAdhan()).thenAnswer((_) async {});
  });

  Widget createWidget({String? payloadJson}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: PrayerNotificationStatusScreen(payloadJson: payloadJson),
    );
  }

  final String validPayload = jsonEncode({
    'prayer_name': 'Fajr',
    'scheduled_time_ms': DateTime.now().millisecondsSinceEpoch,
    'adhan_enabled': true,
    'sound_name': 'adhan_makkah',
  });

  testWidgets('renders loading state initially', (tester) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 100), () => false),
    );

    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);

    // Cleanup pending timer from Future.delayed
    await tester.pumpAndSettle();
  });

  testWidgets('renders prayer details and status chips when loaded', (
    tester,
  ) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('shows Stop button only when Adhan is playing', (tester) async {
    // State 1: Not playing
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();
    expect(find.text('Stop Adhan'), findsNothing);

    // State 2: Playing - use a different key to force BlocProvider re-creation
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
    await tester.pumpWidget(
      Container(
        key: const Key('state_playing'),
        child: createWidget(payloadJson: validPayload),
      ),
    );
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();

    final stopBtn = find.text('Stop Adhan');
    expect(stopBtn, findsOneWidget);

    await tester.tap(stopBtn);
    await tester.pumpAndSettle();

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
