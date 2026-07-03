import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/core/telemetry/sentry_debug_verify_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../support/fake_network_info.dart';
import 'sentry_test_support.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    ServerActionGuard? guard,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: Scaffold(
          body: SentryDebugVerifyTile(serverActionGuard: guard),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows verify tile in debug builds', (tester) async {
    final FakeNetworkInfo networkInfo = FakeNetworkInfo();
    addTearDown(networkInfo.dispose);
    await pumpTile(tester, guard: ServerActionGuard(networkInfo));

    expect(find.text('Verify Sentry setup'), findsOneWidget);
  });

  testWidgets('shows offline toast when server action is blocked', (
    tester,
  ) async {
    final FakeNetworkInfo networkInfo = FakeNetworkInfo(connected: false);
    addTearDown(networkInfo.dispose);
    await pumpTile(tester, guard: ServerActionGuard(networkInfo));

    await tester.tap(find.text('Verify Sentry setup'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No internet connection'),
      findsOneWidget,
    );
  });

  testWidgets('shows warning when Sentry is not initialized', (tester) async {
    final FakeNetworkInfo networkInfo = FakeNetworkInfo();
    addTearDown(networkInfo.dispose);
    await pumpTile(tester, guard: ServerActionGuard(networkInfo));

    await tester.tap(find.text('Verify Sentry setup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sentry is not initialized'), findsOneWidget);
  });

  testWidgets('captures verify exception when Sentry is enabled', (
    tester,
  ) async {
    await ensureSentryInitializedForTests();
    final FakeNetworkInfo networkInfo = FakeNetworkInfo();
    addTearDown(networkInfo.dispose);
    await pumpTile(tester, guard: ServerActionGuard(networkInfo));

    await tester.tap(find.text('Verify Sentry setup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('verify issue'), findsOneWidget);
  });
}
