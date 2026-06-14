import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/presentation/services/in_app_update_snackbar_presenter.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/l10n/generated/app_localizations_en.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('InAppUpdateSnackBarPresenter copy', () {
    test('maps localized strings for prompt actions', () {
      final AppLocalizationsEn l10n = AppLocalizationsEn();

      expect(
        InAppUpdateSnackBarPresenter.messageFor(
          InAppUpdateAction.offerOptionalImmediate,
          l10n,
        ),
        'A new version of Tilawa is available.',
      );
      expect(
        InAppUpdateSnackBarPresenter.actionLabelFor(
          InAppUpdateAction.offerOptionalImmediate,
          l10n,
        ),
        'Update',
      );
      expect(
        InAppUpdateSnackBarPresenter.messageFor(
          InAppUpdateAction.offerRequiredStoreUpdate,
          l10n,
        ),
        'An update is required to continue using Tilawa.',
      );
      expect(
        InAppUpdateSnackBarPresenter.durationFor(
          InAppUpdateAction.offerRequiredStoreUpdate,
        ),
        const Duration(days: 1),
      );
      expect(
        InAppUpdateSnackBarPresenter.messageFor(
          InAppUpdateAction.promptFlexibleRestart,
          l10n,
        ),
        'Update downloaded. Restart when you are ready to install it.',
      );
      expect(
        InAppUpdateSnackBarPresenter.messageFor(
          InAppUpdateAction.none,
          l10n,
        ),
        isEmpty,
      );
    });
  });

  group('InAppUpdateSnackBarPresenter widget', () {
    testWidgets('shows snackbar when context is provided directly', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      final InAppUpdateSnackBarPresenter presenter =
          InAppUpdateSnackBarPresenter();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.primaryCoral,
          ),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      presenter.showPromptForContext(
        tester.element(find.byType(Scaffold)),
        InAppUpdateAction.offerOptionalImmediate,
        onConfirm: () async {
          confirmed = true;
        },
      );
      await tester.pump();

      expect(
        find.text('A new version of Tilawa is available.'),
        findsOneWidget,
      );
      expect(find.text('Update'), findsOneWidget);

      final SnackBar snackBar = tester.widget(find.byType(SnackBar));
      snackBar.action!.onPressed();
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('showPrompt uses AppRouter navigator context', (
      WidgetTester tester,
    ) async {
      final InAppUpdateSnackBarPresenter presenter =
          InAppUpdateSnackBarPresenter();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.primaryCoral,
          ),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      presenter.showPrompt(
        InAppUpdateAction.offerOptionalImmediate,
        onConfirm: () async {},
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('A new version of Tilawa is available.'),
        findsOneWidget,
      );
    });

    testWidgets('showPrompt no-ops without navigator context', (
      WidgetTester tester,
    ) async {
      final InAppUpdateSnackBarPresenter presenter =
          InAppUpdateSnackBarPresenter();

      presenter.showPrompt(
        InAppUpdateAction.offerOptionalImmediate,
        onConfirm: () async {},
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
