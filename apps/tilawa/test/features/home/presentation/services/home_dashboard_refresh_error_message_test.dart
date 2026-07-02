import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/services/home_dashboard_refresh_error_message.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('maps socket failures to offline refresh copy', (tester) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          key: const Key('l10n'),
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final BuildContext context = tester.element(find.byKey(const Key('l10n')));
    expect(
      homeDashboardRefreshErrorMessage(
        context,
        'SocketException: Failed host lookup: example.com',
      ),
      l10n.homeRefreshOfflineMessage,
    );
    expect(
      homeDashboardRefreshErrorMessage(context, 'unexpected'),
      l10n.homeRefreshFailedMessage,
    );
  });
}
