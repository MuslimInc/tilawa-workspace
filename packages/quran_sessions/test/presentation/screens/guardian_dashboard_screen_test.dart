import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Future<void> _pumpGuardianDashboard(
  WidgetTester tester, {
  required VoidCallback onApproveBookings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: const [
        QuranSessionsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: QuranSessionsThemeScope(
        child: GuardianDashboardScreen(onApproveBookings: onApproveBookings),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('approve action invokes host callback', (tester) async {
    var approveTapped = false;

    await _pumpGuardianDashboard(
      tester,
      onApproveBookings: () => approveTapped = true,
    );

    expect(find.text('Guardian hub'), findsOneWidget);
    expect(
      find.textContaining('guardian account linking'),
      findsOneWidget,
    );

    await tester.tap(find.text('Approve child bookings'));
    await tester.pump();

    expect(approveTapped, isTrue);
  });
}
