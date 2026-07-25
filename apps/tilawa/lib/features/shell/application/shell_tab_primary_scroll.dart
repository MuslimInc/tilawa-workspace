import 'package:flutter/material.dart';

/// Isolates inactive shell tabs from the ambient [PrimaryScrollController].
///
/// [NestedScrollView] attaches its outer [ScrollPosition] to the inherited
/// primary controller via [ScrollPosition] parent linkage. [MainTabViewport]
/// keeps visited tabs mounted under [Offstage], so without isolation every
/// tab's NestedScrollView would attach to the same primary controller.
///
/// Reading [ScrollController.offset] / [ScrollController.position] then throws
/// [StateError] (`Bad state: Too many elements`) — Sentry FLUTTER-FQ /
/// FLUTTER-FP.
///
/// Active tabs stay linked so iOS status-bar scroll-to-top still works.
abstract final class ShellTabPrimaryScroll {
  ShellTabPrimaryScroll._();

  /// Wraps [child] so inactive tabs do not attach to the ambient primary.
  static Widget wrap({required bool isActive, required Widget child}) {
    if (isActive) {
      return child;
    }
    return PrimaryScrollController.none(child: child);
  }
}
