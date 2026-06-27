import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable state for [MainScreenCubit].
///
/// Holds all startup-gate flags and tab navigation data that previously
/// lived as raw fields on `_MainScreenState`.
@immutable
class MainScreenState extends Equatable {
  const MainScreenState({
    this.isShellActivated = false,
    this.isInitialTabMounted = false,
    this.isStartupUiWarm = false,
    this.isAudioBindingDeferred = true,
    this.isOfflineIndicatorReady = false,
    this.currentIndex = 0,
    this.builtTabIndexes = const <int>{},
    this.recitersSearchFocusTick = 0,
    this.tabReselectTicks = const <int, int>{},
  });

  /// True once the short post-first-frame shell-activation delay has elapsed.
  final bool isShellActivated;

  /// True once the route-settle delay has elapsed and the initial tab is
  /// ready to be composed into the widget tree.
  final bool isInitialTabMounted;

  /// True once the longer startup-warm delay has elapsed (enables deferred
  /// SVG icons such as the Athkar icon).
  final bool isStartupUiWarm;

  /// False once the audio-binding delay has elapsed; gates [QuranPlayerWidget]
  /// to avoid raster contention during startup.
  final bool isAudioBindingDeferred;

  /// True once the offline-indicator delay has elapsed; gates
  /// [OfflineIndicatorWidget] display to avoid startup frame contention.
  final bool isOfflineIndicatorReady;

  /// Index of the currently selected main tab (0–4).
  ///
  /// Home is index 0. Reciters remains a shell tab at index 1, but is opened
  /// from Home instead of the bottom navigation bar.
  final int currentIndex;

  /// Set of tab indexes that have been selected at least once and therefore
  /// have a live widget subtree (even if currently [Offstage]).
  final Set<int> builtTabIndexes;

  /// Increments when the user re-taps the reciters tab to focus search.
  ///
  /// [RecitersScreen] scrolls to top and focuses the field; the first tap on
  /// the tab only navigates and does not increment this counter.
  final int recitersSearchFocusTick;

  /// Per-tab counters incremented when the user re-taps an active shell tab.
  ///
  /// Tab screens listen for their index and scroll to top or refresh.
  final Map<int, int> tabReselectTicks;

  int tabReselectTick(int tabIndex) => tabReselectTicks[tabIndex] ?? 0;

  MainScreenState copyWith({
    bool? isShellActivated,
    bool? isInitialTabMounted,
    bool? isStartupUiWarm,
    bool? isAudioBindingDeferred,
    bool? isOfflineIndicatorReady,
    int? currentIndex,
    Set<int>? builtTabIndexes,
    int? recitersSearchFocusTick,
    Map<int, int>? tabReselectTicks,
  }) {
    return MainScreenState(
      isShellActivated: isShellActivated ?? this.isShellActivated,
      isInitialTabMounted: isInitialTabMounted ?? this.isInitialTabMounted,
      isStartupUiWarm: isStartupUiWarm ?? this.isStartupUiWarm,
      isAudioBindingDeferred:
          isAudioBindingDeferred ?? this.isAudioBindingDeferred,
      isOfflineIndicatorReady:
          isOfflineIndicatorReady ?? this.isOfflineIndicatorReady,
      currentIndex: currentIndex ?? this.currentIndex,
      builtTabIndexes: builtTabIndexes ?? this.builtTabIndexes,
      recitersSearchFocusTick:
          recitersSearchFocusTick ?? this.recitersSearchFocusTick,
      tabReselectTicks: tabReselectTicks ?? this.tabReselectTicks,
    );
  }

  @override
  List<Object?> get props => [
    isShellActivated,
    isInitialTabMounted,
    isStartupUiWarm,
    isAudioBindingDeferred,
    isOfflineIndicatorReady,
    currentIndex,
    builtTabIndexes,
    recitersSearchFocusTick,
    tabReselectTicks,
  ];
}
