// Regression tests for the delete strip on Tasbeeh saved-dhikr tiles.
//
// Delete lives in a trailing column inside the raised card (no [onTap] on the
// outer [TilawaCard]) so it does not compete with the body [InkWell].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa/features/athkar/presentation/screens/tasbeeh_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fake_tasbeeh_repository.dart';
import '../../helpers/tasbeeh_test_support.dart';

TasbeehCubit _buildCubit(FakeTasbeehRepository repo) => buildTasbeehCubit(repo);

Widget _buildTestApp(TasbeehCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => TasbeehScreen(cubit: cubit),
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.getLightTheme(
      primaryColor: PrimaryColorPreset.defaultPreset.value,
    ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    routerConfig: router,
  );
}

Future<void> _pumpHomeWithSavedDhikr(
  WidgetTester tester,
  TasbeehCubit cubit,
) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await cubit.loadSavedDhikr();

  await tester.pumpWidget(_buildTestApp(cubit));
  await tester.pump();

  expect(cubit.state.viewMode, TasbeehViewMode.home);
  expect(cubit.state.savedDhikr, hasLength(1));
  expect(find.text('Subhan Allah'), findsOneWidget);
}

Future<void> _tapDeleteIcon(WidgetTester tester) async {
  final Finder deleteButton = find.widgetWithIcon(
    TilawaIconActionButton,
    Icons.delete_outline_rounded,
  );
  expect(deleteButton, findsOneWidget);
  await tester.tap(deleteButton);
  await tester.pump();
}

void main() {
  group('Tasbeeh home — delete button', () {
    late FakeTasbeehRepository repo;
    late TasbeehCubit cubit;

    setUp(() {
      repo = FakeTasbeehRepository()
        ..seed(makeDhikr(id: '1', text: 'Subhan Allah', targetCount: 33));
      cubit = _buildCubit(repo);
    });

    tearDown(() async {
      await cubit.close();
    });

    testWidgets(
      'tapping the delete icon shows the confirmation dialog',
      (tester) async {
        await _pumpHomeWithSavedDhikr(tester, cubit);

        await _tapDeleteIcon(tester);

        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason:
              'Delete confirmation dialog must appear when the delete icon is tapped.',
        );
      },
    );

    testWidgets(
      'tapping the delete icon does not navigate away from the home view',
      (tester) async {
        await _pumpHomeWithSavedDhikr(tester, cubit);

        await _tapDeleteIcon(tester);

        expect(
          cubit.state.viewMode,
          TasbeehViewMode.home,
          reason: 'The view must stay on home when the delete icon is tapped.',
        );
      },
    );

    testWidgets(
      'confirming delete removes the item from the saved list',
      (tester) async {
        await _pumpHomeWithSavedDhikr(tester, cubit);

        await _tapDeleteIcon(tester);

        final deleteButtons = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TilawaButton),
        );
        await tester.tapAt(tester.getCenter(deleteButtons.last));
        await tester.pump();

        expect(
          cubit.state.savedDhikr,
          isEmpty,
          reason: 'Saved dhikr list must be empty after confirming deletion.',
        );
      },
    );

    testWidgets(
      'cancelling the delete dialog keeps the item in the saved list',
      (tester) async {
        await _pumpHomeWithSavedDhikr(tester, cubit);

        await _tapDeleteIcon(tester);

        final cancelButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TilawaButton),
        );
        await tester.tapAt(tester.getCenter(cancelButton.first));
        await tester.pump();

        expect(
          cubit.state.savedDhikr,
          hasLength(1),
          reason: 'Item must remain after cancelling the delete dialog.',
        );
      },
    );
  });
}
