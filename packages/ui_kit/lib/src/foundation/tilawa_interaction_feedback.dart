import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';

/// Haptic tiers for kit interactive feedback (spec 015 FR-B03).
enum TilawaHaptic {
  none,
  selection,
  lightImpact,
}

/// Global interaction feedback helpers for press motion and haptics.
///
/// Set [enabled] to `false` in tests to suppress haptics.
abstract final class TilawaInteractionFeedback {
  static bool enabled = true;

  /// Fires a platform haptic when [enabled] is true.
  static void trigger(TilawaHaptic haptic) {
    if (!enabled || haptic == TilawaHaptic.none) {
      return;
    }
    switch (haptic) {
      case TilawaHaptic.none:
        break;
      case TilawaHaptic.selection:
        HapticFeedback.selectionClick();
      case TilawaHaptic.lightImpact:
        HapticFeedback.lightImpact();
    }
  }

  /// Press scale end factor shared by kit press animations.
  static const double pressScaleEnd = 0.96;
}

/// Subtle scale-down while the pointer is down; respects reduced motion.
class TilawaPressAnimation extends StatefulWidget {
  const TilawaPressAnimation({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<TilawaPressAnimation> createState() => _TilawaPressAnimationState();
}

class _TilawaPressAnimationState extends State<TilawaPressAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late Animation<double> _scale;
  bool _controllerDisposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = Theme.of(context).extension<TilawaDesignTokens>();
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = disableMotion
        ? Duration.zero
        : (tokens?.durationFast ?? const Duration(milliseconds: 200));
    _scale = Tween<double>(
      begin: 1,
      end: TilawaInteractionFeedback.pressScaleEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controllerDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (!widget.enabled || !mounted || _controllerDisposed) {
      return;
    }
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
