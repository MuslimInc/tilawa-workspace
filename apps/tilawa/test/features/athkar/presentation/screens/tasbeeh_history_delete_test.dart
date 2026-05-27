// Regression tests for the delete button in the Tasbeeh history view.
//
// Root cause: TilawaCard places its onTap handler as a Positioned.fill
// InkWell overlay rendered last in the Stack (i.e. on top). Flutter's
// hit-test walks children in reverse insertion order and stops as soon as
// any child claims the event.  The transparent InkWell claims every tap
// within the card bounds, so the TilawaIconActionButton inside the card
// content is never reached.
//
// All four tests below fail BEFORE the fix and pass AFTER it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_state.dart';
import 'package:tilawa/features/athkar/presentation/screens/tasbeeh_screen.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fake_tasbeeh_repository.dart';

// ── Test doubles ──────────────────────────────────────────────────────────────

class _SilentFeedbackService implements TasbeehTargetFeedbackService {
  @override
  Future<void> onTargetReached() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

TasbeehCubit _buildCubit(FakeTasbeehRepository repo) => TasbeehCubit(
  getSavedTasbeeh: GetSavedTasbeehUseCase(repo),
  saveCustomTasbeeh: SaveCustomTasbeehUseCase(repo),
  incrementTasbeehCount: IncrementTasbeehCountUseCase(repo),
  resetTasbeehCount: ResetTasbeehCountUseCase(repo),
  setTasbeehTargetCount: SetTasbeehTargetCountUseCase(repo),
  deleteTasbeehDhikr: DeleteTasbeehDhikrUseCase(repo),
  feedbackService: _SilentFeedbackService(),
);

Widget _buildTestApp(TasbeehCubit cubit) => MaterialApp(
  theme: AppTheme.getLightTheme(
    primaryColor: PrimaryColorPreset.defaultPreset.value,
  ),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: TasbeehScreen(cubit: cubit),
);

/// Pumps the TasbeehScreen, waits for the cubit to load, then opens history.
Future<void> _pumpHistory(WidgetTester tester, TasbeehCubit cubit) async {
  await tester.pumpWidget(_buildTestApp(cubit));
  // Let the BlocProvider trigger loadSavedDhikr() and the state to settle.
  await tester.pump();
  cubit.showHistoryView();
  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Tasbeeh history — delete button', () {
    late FakeTasbeehRepository repo;
    late TasbeehCubit cubit;

    setUp(() {
      repo = FakeTasbeehRepository()
        ..seed(makeDhikr(id: '1', text: 'Subhan Allah', targetCount: 33));
      cubit = _buildCubit(repo);
    });

    tearDown(() => cubit.close());

    // ── Bug confirmation (RED before fix) ─────────────────────────────────

    testWidgets(
      'tapping the delete icon shows the confirmation dialog',
      (tester) async {
        await _pumpHistory(tester, cubit);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();

        // Before fix: the card's overlay InkWell fires selectDhikrAndStartCounting
        // instead, the viewMode switches to counting, and no dialog appears.
        expect(
          find.byType(AlertDialog),
          findsOneWidget,
          reason:
              'Delete confirmation dialog must appear when the delete icon is tapped.',
        );
      },
    );

    testWidgets(
      'tapping the delete icon does not navigate away from the history view',
      (tester) async {
        await _pumpHistory(tester, cubit);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();

        // Before fix: the card's onTap fires, switching to counting mode.
        expect(
          cubit.state.viewMode,
          TasbeehViewMode.history,
          reason:
              'The view must stay in history mode when the delete icon is tapped.',
        );
      },
    );

    // ── Correct behaviour after fix ───────────────────────────────────────

    testWidgets(
      'confirming delete removes the item from the history list',
      (tester) async {
        await _pumpHistory(tester, cubit);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();

        // Tap the "Delete" action inside the AlertDialog.
        final deleteButtons = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TilawaButton),
        );
        await tester.tap(deleteButtons.last); // last = danger "Delete" button
        await tester.pump();

        expect(
          cubit.state.savedDhikr,
          isEmpty,
          reason: 'Saved dhikr list must be empty after confirming deletion.',
        );
      },
    );

    testWidgets(
      'cancelling the delete dialog keeps the item in the history list',
      (tester) async {
        await _pumpHistory(tester, cubit);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();

        // Tap the "Cancel" button inside the AlertDialog.
        final cancelButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TilawaButton),
        );
        await tester.tap(cancelButton.first); // first = ghost "Cancel" button
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
