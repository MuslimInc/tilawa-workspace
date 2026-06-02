import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Instant route page for cold-start destinations shown under [BootGate].
///
/// Default [MaterialPage] transitions (fade/slide) can run while the launch
/// splash overlay is still visible or as it is removed, which looks like the
/// splash logo moved or resized. Launch targets should use this instead.
Page<void> launchRoutePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return child;
    },
  );
}
