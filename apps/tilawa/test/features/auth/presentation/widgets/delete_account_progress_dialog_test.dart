import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/presentation/widgets/delete_account_progress_dialog.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final GetIt getIt = GetIt.instance;
  late AccountDeletionFlowTracker tracker;

  setUp(() {
    tracker = AccountDeletionFlowTracker();
    if (getIt.isRegistered<AccountDeletionFlowTracker>()) {
      getIt.unregister<AccountDeletionFlowTracker>();
    }
    getIt.registerSingleton<AccountDeletionFlowTracker>(tracker);
  });

  tearDown(() {
    if (getIt.isRegistered<AccountDeletionFlowTracker>()) {
      getIt.unregister<AccountDeletionFlowTracker>();
    }
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  unawaited(showDeleteAccountProgressDialog(context));
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('pops when deletion ends without success', (tester) async {
    tracker.markDeletionStarted();
    await openDialog(tester);

    expect(find.byType(DeleteAccountProgressDialog), findsOneWidget);

    tracker.markDeletionEndedWithoutSuccess();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DeleteAccountProgressDialog), findsNothing);
  });

  testWidgets('stays open while deletion is in progress', (tester) async {
    tracker.markDeletionStarted();
    await openDialog(tester);

    expect(find.byType(DeleteAccountProgressDialog), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DeleteAccountProgressDialog), findsOneWidget);
  });

  testWidgets('does not pop when deletion succeeds and login navigation runs', (
    tester,
  ) async {
    tracker.markDeletionStarted();
    await openDialog(tester);

    expect(find.byType(DeleteAccountProgressDialog), findsOneWidget);

    tracker.markDeletionSucceeded();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DeleteAccountProgressDialog), findsOneWidget);
    expect(tracker.pendingLoginNavigationAfterDeletion, isTrue);
  });
}
