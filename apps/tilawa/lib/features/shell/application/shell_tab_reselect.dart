import 'package:flutter/material.dart';

/// Scroll-to-top vs refresh when the user re-taps the active shell tab.
abstract final class ShellTabReselect {
  ShellTabReselect._();

  /// Offset above this triggers [scrollToTop] instead of [refresh].
  static const double scrollTopThreshold = 8;

  /// Whether any attached [ScrollPosition] is past [threshold].
  ///
  /// Safe when [scrollController] has zero or multiple clients — unlike
  /// [ScrollController.offset], which throws [StateError] on multiple.
  static bool isScrolledDown(
    ScrollController scrollController, {
    double threshold = scrollTopThreshold,
  }) {
    if (!scrollController.hasClients) {
      return false;
    }
    for (final ScrollPosition position in scrollController.positions) {
      if (position.pixels > threshold) {
        return true;
      }
    }
    return false;
  }

  /// Scrolls to top when [scrollController] is scrolled down; otherwise
  /// [refresh].
  static Future<void> scrollToTopOrRefresh({
    required ScrollController scrollController,
    required Future<void> Function() refresh,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!isScrolledDown(scrollController)) {
      await refresh();
      return;
    }

    await Future.wait<void>([
      for (final ScrollPosition position in scrollController.positions)
        position.animateTo(
          position.minScrollExtent,
          duration: duration,
          curve: curve,
        ),
    ]);
  }
}
