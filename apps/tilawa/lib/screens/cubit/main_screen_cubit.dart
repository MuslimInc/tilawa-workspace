import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_screen_state.dart';

/// Owns all startup-orchestration timers and tab navigation state for the
/// app shell.
///
/// Not `@injectable` — this is app-shell lifecycle scope, not a reusable
/// domain service. Instantiated by `MainScreen` via `BlocProvider(create:)`.
class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(const MainScreenState()) {
    _scheduleStartupTasks();
  }

  // ── Timing constants (must mirror main_screen.dart display logic) ──────────

  static const Duration _shellActivationDelay = Duration(milliseconds: 260);
  static const Duration _initialTabRouteSettleDelay = Duration(
    milliseconds: 1200,
  );
  static const Duration _startupUiWarmupDelay = Duration(milliseconds: 5200);
  static const Duration _deferredAudioBindingDelay = Duration(
    milliseconds: 3800,
  );
  static const Duration _offlineIndicatorDelay = Duration(milliseconds: 3000);

  // ── Timers ─────────────────────────────────────────────────────────────────

  Timer? _shellActivationTimer;
  Timer? _initialTabMountTimer;
  Timer? _startupUiWarmupTimer;
  Timer? _audioBindingTimer;
  Timer? _offlineIndicatorTimer;

  // ── Startup orchestration ──────────────────────────────────────────────────

  void _scheduleStartupTasks() {
    // Phase A: activate the outer shell after a short post-first-frame delay
    // to avoid contention with the route-entrance transition.
    _shellActivationTimer = Timer(_shellActivationDelay, () {
      if (isClosed) return;
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (isClosed) return;
          emit(state.copyWith(isShellActivated: true));
          if (!kReleaseMode) {
            debugPrint(
              '[PerfLogger][MainScreen] shell-activated '
              'delayMs=${_shellActivationDelay.inMilliseconds}',
            );
          }
        },
        Priority.idle,
        debugLabel: 'main-screen-shell-activation',
      );
    });

    // Phase B: mount the initial tab after the route has settled to prevent
    // a single heavy composition frame at the start of the transition.
    _initialTabMountTimer = Timer(_initialTabRouteSettleDelay, () {
      if (isClosed) return;
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (isClosed) return;
          emit(
            state.copyWith(
              isInitialTabMounted: true,
              builtTabIndexes: {...state.builtTabIndexes, state.currentIndex},
            ),
          );
          if (!kReleaseMode) {
            debugPrint(
              '[PerfLogger][MainScreen] initial-tab-mounted '
              'delayMs=${_initialTabRouteSettleDelay.inMilliseconds}',
            );
          }
        },
        Priority.idle,
        debugLabel: 'main-screen-initial-tab-mount',
      );
    });

    // Phase C: enable deferred UI elements (e.g. SVG icons) after the
    // critical startup window is clear.
    _startupUiWarmupTimer = Timer(_startupUiWarmupDelay, () {
      if (isClosed) return;
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (isClosed) return;
          emit(state.copyWith(isStartupUiWarm: true));
          if (!kReleaseMode) {
            debugPrint(
              '[PerfLogger][MainScreen] startup-ui-warm '
              'delayMs=${_startupUiWarmupDelay.inMilliseconds}',
            );
          }
        },
        Priority.idle,
        debugLabel: 'main-screen-startup-warmup',
      );
    });

    // Phase D: bind audio player after the critical startup window is clear.
    if (!kReleaseMode) {
      debugPrint(
        '[PerfLogger][MainScreen] audio-binding scheduled '
        'delayMs=${_deferredAudioBindingDelay.inMilliseconds}',
      );
    }
    _audioBindingTimer = Timer(_deferredAudioBindingDelay, () {
      if (isClosed) return;
      if (!kReleaseMode) {
        debugPrint('[PerfLogger][MainScreen] audio-binding started');
      }
      emit(state.copyWith(isAudioBindingDeferred: false));
    });

    // Phase E: show offline indicator after the startup window.
    _offlineIndicatorTimer = Timer(_offlineIndicatorDelay, () {
      if (isClosed) return;
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (isClosed) return;
          emit(state.copyWith(isOfflineIndicatorReady: true));
        },
        Priority.idle,
        debugLabel: 'main-screen-offline-indicator',
      );
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Switches the active tab and marks it as built so [MainTabViewport] keeps
  /// its subtree alive.
  void selectTab(int index) {
    if (state.currentIndex == index) return;
    emit(
      state.copyWith(
        currentIndex: index,
        builtTabIndexes: {...state.builtTabIndexes, index},
      ),
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _shellActivationTimer?.cancel();
    _initialTabMountTimer?.cancel();
    _startupUiWarmupTimer?.cancel();
    _audioBindingTimer?.cancel();
    _offlineIndicatorTimer?.cancel();
    return super.close();
  }
}
