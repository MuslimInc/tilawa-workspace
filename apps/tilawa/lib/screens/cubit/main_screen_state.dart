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
  });

  /// True once the short post-first-frame shell-activation delay has elapsed.
  final bool isShellActivated;

  /// True once the route-settle delay has elapsed and the initial tab is
  /// ready to be composed into the widget tree.
  final bool isInitialTabMounted;

  /// True once the longer startup-warm delay has elapsed (enables deferred
  /// SVG icons such as the Athkar icon).
  final bool isStartupUiWarm;

  /// False once the audio-binding delay has elapsed; gates [BottomPlayerWidget]
  /// to avoid raster contention during startup.
  final bool isAudioBindingDeferred;

  /// True once the offline-indicator delay has elapsed; gates
  /// [OfflineIndicatorWidget] display to avoid startup frame contention.
  final bool isOfflineIndicatorReady;

  /// Index of the currently selected main tab (0–3).
  final int currentIndex;

  /// Set of tab indexes that have been selected at least once and therefore
  /// have a live widget subtree (even if currently [Offstage]).
  final Set<int> builtTabIndexes;

  MainScreenState copyWith({
    bool? isShellActivated,
    bool? isInitialTabMounted,
    bool? isStartupUiWarm,
    bool? isAudioBindingDeferred,
    bool? isOfflineIndicatorReady,
    int? currentIndex,
    Set<int>? builtTabIndexes,
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
  ];
}
