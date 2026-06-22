import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_action.dart';
import 'package:tilawa/features/in_app_update/presentation/services/in_app_update_feedback_presenter.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/l10n/generated/app_localizations_en.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('InAppUpdateFeedbackPresenter copy', () {
    test('maps localized strings for prompt actions', () {
      final AppLocalizationsEn l10n = AppLocalizationsEn();

      expect(
        InAppUpdateFeedbackPresenter.messageFor(
          InAppUpdateAction.offerOptionalImmediate,
          l10n,
        ),
        'A new version of Tilawa is available.',
      );
      expect(
        InAppUpdateFeedbackPresenter.actionLabelFor(
          InAppUpdateAction.offerOptionalImmediate,
          l10n,
        ),
        'Update',
      );
      expect(
        InAppUpdateFeedbackPresenter.messageFor(
          InAppUpdateAction.offerRequiredStoreUpdate,
          l10n,
        ),
        'An update is required to continue using Tilawa.',
      );
      expect(
        InAppUpdateFeedbackPresenter.durationFor(
          InAppUpdateAction.offerOptionalImmediate,
        ),
        InAppUpdateFeedbackPresenter.promptDuration,
      );
      expect(
        InAppUpdateFeedbackPresenter.durationFor(
          InAppUpdateAction.offerRequiredStoreUpdate,
        ),
        isNull,
      );
      expect(
        InAppUpdateFeedbackPresenter.messageFor(
          InAppUpdateAction.promptFlexibleRestart,
          l10n,
        ),
        'Update downloaded. Restart when you are ready to install it.',
      );
      expect(
        InAppUpdateFeedbackPresenter.messageFor(
          InAppUpdateAction.none,
          l10n,
        ),
        isEmpty,
      );
    });
  });

  group('InAppUpdateFeedbackPresenter widget', () {
    Future<void> pumpWithFeedbackHost(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.primaryCoral,
          ),
          home: TilawaFeedbackHost(child: child),
        ),
      );
    }

    testWidgets('shows actionable toast when context is provided directly', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      final InAppUpdateFeedbackPresenter presenter =
          InAppUpdateFeedbackPresenter();

      await pumpWithFeedbackHost(
        tester,
        const Scaffold(body: SizedBox.shrink()),
      );

      presenter.showPromptForContext(
        tester.element(find.byType(Scaffold)),
        InAppUpdateAction.offerOptionalImmediate,
        onConfirm: () async {
          confirmed = true;
        },
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('A new version of Tilawa is available.'),
        findsOneWidget,
      );
      expect(find.text('Update'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('shows persistent actionable toast for required store update', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      final InAppUpdateFeedbackPresenter presenter =
          InAppUpdateFeedbackPresenter();

      await pumpWithFeedbackHost(
        tester,
        const Scaffold(body: SizedBox.shrink()),
      );

      presenter.showPromptForContext(
        tester.element(find.byType(Scaffold)),
        InAppUpdateAction.offerRequiredStoreUpdate,
        onConfirm: () async {
          confirmed = true;
        },
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('An update is required to continue using Tilawa.'),
        findsOneWidget,
      );
      expect(find.byType(TilawaFeedbackStrip), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pump();
      expect(confirmed, isTrue);
      await tester.pumpAndSettle();
      expect(
        find.text('An update is required to continue using Tilawa.'),
        findsNothing,
      );
    });

    testWidgets('showPrompt uses AppRouter navigator context', (
      WidgetTester tester,
    ) async {
      final InAppUpdateFeedbackPresenter presenter =
          InAppUpdateFeedbackPresenter();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.primaryCoral,
          ),
          builder: (context, child) => TilawaFeedbackHost(child: child!),
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
      final InAppUpdateFeedbackPresenter presenter =
          InAppUpdateFeedbackPresenter();

      presenter.showPrompt(
        InAppUpdateAction.offerOptionalImmediate,
        onConfirm: () async {},
      );
      await tester.pump();

      expect(find.byType(TilawaFeedbackStrip), findsNothing);
    });

    testWidgets('showPromptForContext no-ops for non-prompt actions', (
      WidgetTester tester,
    ) async {
      final InAppUpdateFeedbackPresenter presenter =
          InAppUpdateFeedbackPresenter();

      await pumpWithFeedbackHost(
        tester,
        const Scaffold(body: SizedBox.shrink()),
      );

      for (final InAppUpdateAction action in <InAppUpdateAction>[
        InAppUpdateAction.performImmediate,
        InAppUpdateAction.startFlexible,
        InAppUpdateAction.none,
      ]) {
        presenter.showPromptForContext(
          tester.element(find.byType(Scaffold)),
          action,
          onConfirm: () async {},
        );
        await tester.pump();

        expect(find.byType(TilawaFeedbackStrip), findsNothing);
      }
    });
  });
}
