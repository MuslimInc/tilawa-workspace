import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/forced_update/presentation/widgets/forced_update_gate_page.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('ForcedUpdateGatePage invokes CTA and refuses back pop', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
        home: ForcedUpdateGatePage(
          onUpdatePressed: () {
            tapped = true;
          },
        ),
      ),
    );

    expect(find.text('Update required'), findsOneWidget);
    expect(
      find.text('An update is required to continue using MeMuslim.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Update'));
    await tester.pump();
    expect(tapped, isTrue);

    final PopScope popScope = tester.widget(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });
}
