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
  });

  Widget createWidget({String? payloadJson}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
    // Check for indicator or just verify it hasn't settled yet
    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
  });

  testWidgets('renders prayer details and status chips when loaded', (
    tester,
  ) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);

    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Adhan'), findsOneWidget);
    // Localization of 'Enabled' might be capitalized or not
    expect(find.text('Enabled'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('adhan_makkah'), findsOneWidget);
  });

  testWidgets('shows Stop button only when Adhan is playing', (tester) async {
    // State 1: Not playing
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => false);
    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();
    expect(find.text('Stop Adhan'), findsNothing);

    // State 2: Playing
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
    // Re-create to force fresh Cubit init with playing state
    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();
    expect(find.text('Stop Adhan'), findsOneWidget);
  });

  testWidgets('calls stopCurrentAdhan when Stop button is pressed', (
    tester,
  ) async {
    when(mockAdhanPlayer.isAdhanPlaying()).thenAnswer((_) async => true);
    await tester.pumpWidget(createWidget(payloadJson: validPayload));
    await tester.pumpAndSettle();

    final stopBtn = find.text('Stop Adhan');
    expect(stopBtn, findsOneWidget);
    await tester.tap(stopBtn);
    await tester.pump();

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
