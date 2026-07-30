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
  ///
  /// Both branches emit a [PrimaryScrollController] so that toggling
  /// [isActive] updates that element in place. Returning [child] unwrapped
  /// while active would change the widget type at this slot on every tab
  /// switch, unmounting and rebuilding the whole tab subtree — which closes
  /// the tab's blocs mid-flight (Sentry FLUTTER-DT).
  static Widget wrap({required bool isActive, required Widget child}) {
    return Builder(
      builder: (BuildContext context) {
        final PrimaryScrollController? ambient = isActive
            ? context
                  .dependOnInheritedWidgetOfExactType<PrimaryScrollController>()
            : null;
        final ScrollController? controller = ambient?.controller;
        if (ambient == null || controller == null) {
          return PrimaryScrollController.none(child: child);
        }
        return PrimaryScrollController(
          controller: controller,
          automaticallyInheritForPlatforms:
              ambient.automaticallyInheritForPlatforms,
          scrollDirection: ambient.scrollDirection ?? Axis.vertical,
          child: child,
        );
      },
    );
  }
}
