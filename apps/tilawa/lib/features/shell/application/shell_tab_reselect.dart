import 'package:flutter/material.dart';

/// Scroll-to-top vs refresh when the user re-taps the active shell tab.
abstract final class ShellTabReselect {
  ShellTabReselect._();

  /// Offset above this triggers [scrollToTop] instead of [refresh].
  static const double scrollTopThreshold = 8;

  /// Scrolls to top when [scrollController] is scrolled down; otherwise
  /// [refresh].
  static Future<void> scrollToTopOrRefresh({
    required ScrollController scrollController,
    required Future<void> Function() refresh,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (scrollController.hasClients &&
        scrollController.offset > scrollTopThreshold) {
      await scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: duration,
        curve: curve,
      );
      return;
    }
    await refresh();
  }
}
