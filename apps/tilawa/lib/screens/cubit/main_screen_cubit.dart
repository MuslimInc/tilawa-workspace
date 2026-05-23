import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/di/injection.dart';

import 'main_screen_state.dart';

const bool _kReleaseMode = bool.fromEnvironment(
  'dart.vm.product',
  defaultValue: false,
);

/// Owns startup-orchestration timers and tab navigation state for the app shell.
///
/// Shell/tab prep may complete on the splash screen via [AppStartupReadiness];
/// this cubit skips those delays when [AppStartupReadiness.shellPrepComplete]
/// is already true.
class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit({AppStartupReadiness? readiness})
    : _readiness = readiness ?? _resolveReadiness(),
      super(_initialState(readiness ?? _resolveReadiness())) {
    if (_readiness?.shellPrepComplete ?? false) {
      _scheduleDeferredStartupTasks();
    } else {
      _scheduleFullStartupTasks();
    }
  }

  final AppStartupReadiness? _readiness;

  static AppStartupReadiness? _resolveReadiness() {
    if (!getIt.isRegistered<AppStartupReadiness>()) {
      return null;
    }
    return getIt<AppStartupReadiness>();
  }

  static MainScreenState _initialState(AppStartupReadiness? readiness) {
    if (readiness?.shellPrepComplete ?? false) {
      return const MainScreenState(
        isShellActivated: true,
        isInitialTabMounted: true,
        builtTabIndexes: <int>{0},
      );
    }
    return const MainScreenState();
  }

  static const Duration _shellActivationDelay =
      AppStartupReadiness.shellActivationDelay;
  static const Duration _initialTabRouteSettleDelay =
      AppStartupReadiness.initialTabRouteSettleDelay;
  static const Duration _startupUiWarmupDelay = Duration(milliseconds: 5200);
  static const Duration _deferredAudioBindingDelay = Duration(
    milliseconds: 800,
  );
  static const Duration _offlineIndicatorDelay = Duration(milliseconds: 600);

  Timer? _shellActivationTimer;
  Timer? _initialTabMountTimer;
  Timer? _startupUiWarmupTimer;
  Timer? _audioBindingTimer;
  Timer? _offlineIndicatorTimer;

  void _scheduleFullStartupTasks() {
    _shellActivationTimer = Timer(_shellActivationDelay, () {
      if (isClosed) return;
      emit(state.copyWith(isShellActivated: true));
      if (!_kReleaseMode) {
        developer.log(
          '[PerfLogger][MainScreen] shell-activated '
          'delayMs=${_shellActivationDelay.inMilliseconds}',
          name: 'tilawa.main_screen',
        );
      }
    });

    _initialTabMountTimer = Timer(_initialTabRouteSettleDelay, () {
      if (isClosed) return;
      emit(
        state.copyWith(
          isInitialTabMounted: true,
          builtTabIndexes: {...state.builtTabIndexes, state.currentIndex},
        ),
      );
      if (!_kReleaseMode) {
        developer.log(
          '[PerfLogger][MainScreen] initial-tab-mounted '
          'delayMs=${_initialTabRouteSettleDelay.inMilliseconds}',
          name: 'tilawa.main_screen',
        );
      }
    });

    _scheduleDeferredStartupTasks();
  }

  void _scheduleDeferredStartupTasks() {
    _startupUiWarmupTimer = Timer(_startupUiWarmupDelay, () {
      if (isClosed) return;
      emit(state.copyWith(isStartupUiWarm: true));
      if (!_kReleaseMode) {
        developer.log(
          '[PerfLogger][MainScreen] startup-ui-warm '
          'delayMs=${_startupUiWarmupDelay.inMilliseconds}',
          name: 'tilawa.main_screen',
        );
      }
    });

    if (!_kReleaseMode) {
      developer.log(
        '[PerfLogger][MainScreen] audio-binding scheduled '
        'delayMs=${_deferredAudioBindingDelay.inMilliseconds}',
        name: 'tilawa.main_screen',
      );
    }
    _audioBindingTimer = Timer(_deferredAudioBindingDelay, () {
      if (isClosed) return;
      if (!_kReleaseMode) {
        developer.log(
          '[PerfLogger][MainScreen] audio-binding started',
          name: 'tilawa.main_screen',
        );
      }
      emit(state.copyWith(isAudioBindingDeferred: false));
    });

    _offlineIndicatorTimer = Timer(_offlineIndicatorDelay, () {
      if (isClosed) return;
      scheduleMicrotask(() {
        if (isClosed) return;
        emit(state.copyWith(isOfflineIndicatorReady: true));
      });
    });
  }

  void selectTab(int index, {bool force = false}) {
    if (!force && state.currentIndex == index) {
      return;
    }
    emit(
      state.copyWith(
        currentIndex: index,
        builtTabIndexes: {...state.builtTabIndexes, index},
      ),
    );
  }

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
