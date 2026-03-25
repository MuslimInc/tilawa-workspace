import 'package:flutter/widgets.dart';

/// Minimal test-only compatibility layer for legacy widget tests.
///
/// Production code should use standard Flutter layout primitives instead.
class ScreenUtilPlusInit extends StatelessWidget {
  const ScreenUtilPlusInit({
    super.key,
    this.child,
    this.builder,
    this.designSize = const Size(390, 844),
    this.minTextAdapt = false,
    this.splitScreenMode = false,
  });

  final Widget? child;
  final TransitionBuilder? builder;
  final Size designSize;
  final bool minTextAdapt;
  final bool splitScreenMode;

  @override
  Widget build(BuildContext context) {
    return builder?.call(context, child) ?? child ?? const SizedBox.shrink();
  }
}

class ScreenUtilPlus {
  const ScreenUtilPlus._();

  static void init(
    BuildContext context, {
    Size designSize = const Size(390, 844),
    bool minTextAdapt = false,
    bool splitScreenMode = false,
  }) {}
}
