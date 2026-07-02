import 'package:flutter/foundation.dart';

/// Debug-only override that pins the Home dashboard to its skeleton
/// loading state for visual review (Settings → Developer → Force Home
/// skeleton).
///
/// [HomeScreen] substitutes `HomeDashboardLoading` for the real bloc state
/// while [forceSkeleton] is on, so the hero and body shimmer indefinitely.
/// [isForced] is hard-wired to `false` outside debug builds, so release
/// behavior can never be affected. Delete this file (and its two call
/// sites) to remove the tool.
abstract final class HomeSkeletonDebug {
  const HomeSkeletonDebug._();

  /// Toggle state driven by the Developer settings switch.
  static final ValueNotifier<bool> forceSkeleton = ValueNotifier<bool>(false);

  /// Whether the Home skeleton is currently forced. Always false in release.
  static bool get isForced => kDebugMode && forceSkeleton.value;
}
