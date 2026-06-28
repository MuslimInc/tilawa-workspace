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
///
/// When [pressedNotifier] is supplied the internal [Listener] is disabled and
/// the animation follows the notifier instead. [TilawaInteractiveSurface] uses
/// this so nested Material controls can own their press feedback without the
/// parent surface scaling.
class TilawaPressAnimation extends StatefulWidget {
  const TilawaPressAnimation({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedNotifier,
  });

  final Widget child;
  final bool enabled;

  /// When non-null, drives press scale instead of pointer listeners on [child].
  final ValueNotifier<bool>? pressedNotifier;

  @override
  State<TilawaPressAnimation> createState() => _TilawaPressAnimationState();
}

class _TilawaPressAnimationState extends State<TilawaPressAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late Animation<double> _scale;
  bool _controllerDisposed = false;

  @override
  void initState() {
    super.initState();
    widget.pressedNotifier?.addListener(_onExternalPressed);
  }

  @override
  void didUpdateWidget(covariant TilawaPressAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressedNotifier != widget.pressedNotifier) {
      oldWidget.pressedNotifier?.removeListener(_onExternalPressed);
      widget.pressedNotifier?.addListener(_onExternalPressed);
    }
  }

  void _onExternalPressed() {
    _setPressed(widget.pressedNotifier!.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = Theme.of(context).extension<MeMuslimDesignTokens>();
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
    widget.pressedNotifier?.removeListener(_onExternalPressed);
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

    final Widget scaledChild = ScaleTransition(
      scale: _scale,
      child: widget.child,
    );

    if (widget.pressedNotifier != null) {
      return scaledChild;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: scaledChild,
    );
  }
}
