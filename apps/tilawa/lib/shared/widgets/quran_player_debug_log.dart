import 'package:flutter/animation.dart';

import 'quran_player_visual_mode.dart';

/// Debug-only Quran player diagnostics (no output in profile/release).
///
/// Enable in debug builds, or with
/// `--dart-define=QURAN_PLAYER_DEBUG_LOG=true`.
abstract final class QuranPlayerDebugLog {
  static bool get enabled => const bool.fromEnvironment(
    'QURAN_PLAYER_DEBUG_LOG',
    defaultValue: true,
  );

  static String playerMode({
    required double expandProgress,
    required bool isCollapsing,
    required bool isUserDragging,
    String? transitionOwner,
  }) => quranPlayerVisualMode(
    expandProgress: expandProgress,
    isCollapsing: isCollapsing,
    isUserDragging: isUserDragging,
    transitionOwner: transitionOwner,
  );

  static double curvedRouteProgress(double raw, AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      return Curves.fastOutSlowIn.flipped.transform(raw);
    }
    return Curves.fastOutSlowIn.transform(raw);
  }

  static void log(String event, [Map<String, Object?> fields = const {}]) {}

  static void warn(String event, [Map<String, Object?> fields = const {}]) {}

  static void hero(String event, [Map<String, Object?> fields = const {}]) {}

  static void lifecycle(
    String phase, [
    Map<String, Object?> fields = const {},
  ]) {}

  static void animation(
    String event, [
    Map<String, Object?> fields = const {},
  ]) {}

  static void drag(String event, [Map<String, Object?> fields = const {}]) {}

  static void layout(String event, [Map<String, Object?> fields = const {}]) {}

  static void gesture(String event, [Map<String, Object?> fields = const {}]) {}

  static void route(String event, [Map<String, Object?> fields = const {}]) {}

  static void overlay(String event, [Map<String, Object?> fields = const {}]) {}

  static void maybeWarnTransitionGap({
    required double progress,
    required double miniOpacity,
    required double expandedOpacity,
    required String source,
  }) {}
}
