import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';

// NOTE: testWidgets tests that only advance time partially must call
// `await cubit.close()` in the test body (not addTearDown). The Flutter test
// framework runs _verifyInvariants (pending-timer check) before teardown
// callbacks, so any un-cancelled timers would cause a spurious failure.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Initial state ────────────────────────────────────────────────────────

  group('initial state', () {
    test('starts with all startup gates closed', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      expect(cubit.state, const MainScreenState());
      expect(cubit.state.isShellActivated, isFalse);
      expect(cubit.state.isInitialTabMounted, isFalse);
      expect(cubit.state.isStartupUiWarm, isFalse);
      expect(cubit.state.isAudioBindingDeferred, isTrue);
      expect(cubit.state.isOfflineIndicatorReady, isFalse);
    });

    test('starts on tab 0 with an empty built-index set', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.builtTabIndexes, isEmpty);
    });
  });

  // ── Startup gate timers ──────────────────────────────────────────────────

  group('startup gate timers', () {
    testWidgets('emits isShellActivated=true after the 260 ms delay', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      expect(cubit.state.isShellActivated, isFalse);

      await tester.pump(const Duration(milliseconds: 260));
      await tester.pump(); // flush idle scheduler task

      expect(cubit.state.isShellActivated, isTrue);

      await cubit.close(); // cancel remaining timers before invariant check
    });

    testWidgets('does not emit isShellActivated=true before 260 ms', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 259));
      await tester.pump();

      expect(cubit.state.isShellActivated, isFalse);

      await cubit.close();
    });

    testWidgets('emits isInitialTabMounted=true and adds currentIndex to '
        'builtTabIndexes after initialTabRouteSettleDelay', (tester) async {
      final cubit = MainScreenCubit();

      await tester.pump(AppStartupReadiness.initialTabRouteSettleDelay);
      await tester.pump();

      expect(cubit.state.isInitialTabMounted, isTrue);
      expect(cubit.state.builtTabIndexes, contains(0));

      await cubit.close();
    });

    testWidgets('does not emit isInitialTabMounted=true before '
        'initialTabRouteSettleDelay', (tester) async {
      final cubit = MainScreenCubit();

      await tester.pump(
        AppStartupReadiness.initialTabRouteSettleDelay -
            const Duration(milliseconds: 1),
      );
      await tester.pump();

      expect(cubit.state.isInitialTabMounted, isFalse);

      await cubit.close();
    });

    testWidgets('emits isOfflineIndicatorReady=true after the 600 ms delay', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(cubit.state.isOfflineIndicatorReady, isTrue);

      await cubit.close();
    });

    testWidgets('emits isAudioBindingDeferred=false after the 800 ms delay', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();

      expect(cubit.state.isAudioBindingDeferred, isFalse);

      await cubit.close();
    });

    testWidgets('emits isStartupUiWarm=true after the 5200 ms delay', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 5200));
      await tester.pump();

      expect(cubit.state.isStartupUiWarm, isTrue);

      // All timers have fired at this point; close is still good practice.
      await cubit.close();
    });

    testWidgets('gate flags respect their individual delays '
        '(only shell active at 260 ms)', (tester) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 260));
      await tester.pump();

      expect(cubit.state.isShellActivated, isTrue);
      expect(cubit.state.isInitialTabMounted, isFalse);
      expect(cubit.state.isOfflineIndicatorReady, isFalse);
      expect(cubit.state.isAudioBindingDeferred, isTrue);
      expect(cubit.state.isStartupUiWarm, isFalse);

      await cubit.close();
    });

    testWidgets('all gates are open after the full 5200 ms startup window', (
      tester,
    ) async {
      final cubit = MainScreenCubit();

      await tester.pump(const Duration(milliseconds: 5200));
      await tester.pump();

      expect(cubit.state.isShellActivated, isTrue);
      expect(cubit.state.isInitialTabMounted, isTrue);
      expect(cubit.state.isOfflineIndicatorReady, isTrue);
      expect(cubit.state.isAudioBindingDeferred, isFalse);
      expect(cubit.state.isStartupUiWarm, isTrue);

      await cubit.close();
    });
  });

  // ── selectTab ────────────────────────────────────────────────────────────

  group('selectTab', () {
    test('updates currentIndex', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(2);

      expect(cubit.state.currentIndex, 2);
    });

    test('adds the new index to builtTabIndexes', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(3);

      expect(cubit.state.builtTabIndexes, contains(3));
    });

    test('accumulates all previously visited indexes', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(1);
      cubit.selectTab(2);
      cubit.selectTab(3);

      expect(cubit.state.builtTabIndexes, containsAll([1, 2, 3]));
      expect(cubit.state.currentIndex, 3);
    });

    test('is a no-op when selecting the already-active tab', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      final stateBefore = cubit.state;
      cubit.selectTab(0); // 0 is the default

      expect(cubit.state, same(stateBefore));
    });

    test('does not remove a previously built index when switching away', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(1);
      cubit.selectTab(2);
      cubit.selectTab(1); // back to 1

      expect(cubit.state.builtTabIndexes, containsAll([1, 2]));
      expect(cubit.state.currentIndex, 1);
    });
  });

  // ── Reciters tab / search focus ─────────────────────────────────────────

  group('requestRecitersSearchFocus', () {
    test('increments recitersSearchFocusTick', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.requestRecitersSearchFocus();

      expect(cubit.state.recitersSearchFocusTick, 1);
    });

    test('selecting reciters tab does not increment focus tick', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(1);
      cubit.selectTab(0, force: true);

      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.recitersSearchFocusTick, 0);
    });

    test('moves to tab 0 from another tab when requesting search focus', () {
      final cubit = MainScreenCubit();
      addTearDown(cubit.close);

      cubit.selectTab(2);
      cubit.requestRecitersSearchFocus();

      expect(cubit.state.currentIndex, 0);
      expect(cubit.state.builtTabIndexes, contains(0));
      expect(cubit.state.recitersSearchFocusTick, 1);
    });
  });

  // ── close (timer cancellation) ───────────────────────────────────────────

  group('close', () {
    testWidgets(
      'cancels all startup timers so no state is emitted after close',
      (tester) async {
        final cubit = MainScreenCubit();

        // Close immediately before any timer fires.
        await cubit.close();

        // Advance well past all delays – the cubit is already closed, so the
        // `if (isClosed) return;` guards must prevent any emission.
        // If those guards were missing this would throw a StateError.
        await tester.pump(const Duration(milliseconds: 6000));
        await tester.pump();

        // Reaching this line without an error confirms proper cancellation.
      },
    );
  });
}
