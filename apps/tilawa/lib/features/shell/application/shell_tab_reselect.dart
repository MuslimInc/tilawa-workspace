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

    await _animatePositionsToTop(
      scrollController,
      duration: duration,
      curve: curve,
    );
  }

  /// Fully expands a [NestedScrollView]: body first, then header.
  ///
  /// Parallel [ScrollController.animateTo] on outer+inner leaves the outer
  /// pinned at max (coordinator race). Drive inner to min, then outer, then
  /// hard-jump settle.
  static Future<void> scrollNestedToTop({
    required ScrollController outer,
    required ScrollController inner,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (inner.hasClients) {
      await _animatePositionsToTop(inner, duration: duration, curve: curve);
    }
    _jumpPositionsToTop(inner);

    if (outer.hasClients) {
      await _animatePositionsToTop(outer, duration: duration, curve: curve);
    }
    _jumpPositionsToTop(outer);
  }

  static Future<void> _animatePositionsToTop(
    ScrollController scrollController, {
    required Duration duration,
    required Curve curve,
  }) {
    return Future.wait<void>([
      for (final ScrollPosition position in List<ScrollPosition>.of(
        scrollController.positions,
      ))
        if (position.hasPixels)
          position.animateTo(
            position.minScrollExtent,
            duration: duration,
            curve: curve,
          ),
    ]);
  }

  static void _jumpPositionsToTop(ScrollController scrollController) {
    if (!scrollController.hasClients) {
      return;
    }
    for (final ScrollPosition position in List<ScrollPosition>.of(
      scrollController.positions,
    )) {
      if (!position.hasPixels) {
        continue;
      }
      if (position.pixels != position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
      }
    }
  }
}

