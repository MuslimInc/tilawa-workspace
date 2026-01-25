import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/history/presentation/widgets/history_stats_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  Widget createWidget({
    required int totalItems,
    required int totalListeningTimeMs,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HistoryStatsCard(
          totalItems: totalItems,
          totalListeningTimeMs: totalListeningTimeMs,
        ),
      ),
    );
  }

  testWidgets('HistoryStatsCard renders correctly', (tester) async {
    await tester.pumpWidget(
      createWidget(totalItems: 10, totalListeningTimeMs: 65000), // 1m 5s
    );
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget);
    expect(
      find.text('Total Surahs'),
      findsOneWidget,
    ); // Assuming l10n.totalSurahs defaults to matching "Surahs" or close
    expect(find.text('1m 5s'), findsOneWidget);
    expect(find.byIcon(Icons.library_music), findsOneWidget);
    expect(find.byIcon(Icons.access_time_filled), findsOneWidget);
  });

  testWidgets('HistoryStatsCard formats duration gracefully (only seconds)', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(totalItems: 5, totalListeningTimeMs: 30000), // 30s
    );
    await tester.pumpAndSettle();

    expect(find.text('30s'), findsOneWidget);
  });

  testWidgets('HistoryStatsCard formats duration gracefully (hours)', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(totalItems: 5, totalListeningTimeMs: 3660000), // 1h 1m
    );
    await tester.pumpAndSettle();

    expect(find.text('1h 1m'), findsOneWidget);
  });
}
