import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../atoms/tilawa_button.dart';
import 'design_tokens.dart';
import 'tilawa_interaction_feedback.dart';

/// The single interaction primitive for the Tilawa UI kit.
///
/// Wrapping a tappable surface in [TilawaInteractiveSurface] guarantees the
/// kit's full interaction contract in one place, so individual atoms and
/// molecules stop re-implementing (and drifting on) it:
///
/// - **Focus ring** — a visible 2 dp ring on keyboard / switch / D-pad focus,
///   drawn from [MeMuslimDesignTokens.focusRingWidth]. Fixes the WCAG 2.4.7
///   gap where most components had no focus state (audit UIK-005).
/// - **Press feel** — the shared scale-to-0.96 press animation via
///   [TilawaPressAnimation], so every surface presses the same way and honours
///   reduced-motion (UIK-006).
/// - **Haptics** — a single [TilawaHaptic] tier fired on activation, instead of
///   ad-hoc per-component haptics (UIK-007).
/// - **State layers** — hover / pressed / focused washes resolved from
///   [MeMuslimDesignTokens.stateLayerHover] / `stateLayerPressed` /
///   `stateLayerFocused` (UIK-008).
///
/// It is intentionally *unopinionated about paint*: the caller supplies the
/// resting [child] (fill, border, content). The kit's interactive atoms,
/// molecules, and organisms route through this primitive instead of a raw
/// [Material] + [InkWell] pair, so the whole app shares one press-scale feel
/// (no ink ripple) plus a consistent focus ring, haptics, and state layers.
///
/// ## Usage
///
/// ```dart
/// TilawaInteractiveSurface(
///   onTap: _open,
///   borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
///   haptic: TilawaHaptic.selection,
///   child: const _CardBody(),
/// )
/// ```
///
/// Pass `onTap: null` for a non-interactive surface; the wrapper then renders
/// [child] directly with no focus/press/haptic overhead.
///
/// ## Nested interactive children
///
/// Nested controls inside a tappable card own their interaction area. Enabled
/// controls handle their own action; disabled controls become dead zones. The
/// parent card should only navigate and show press feedback from blank/
/// non-interactive card areas.
class TilawaInteractiveSurface extends StatefulWidget {
  const TilawaInteractiveSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.haptic = TilawaHaptic.selection,
    this.enablePressAnimation = true,
    this.enableStateLayer = true,
    this.focusColor,
    this.stateLayerColor,
    this.semanticLabel,
    this.semanticHint,
    this.button = true,
    this.selected,
    this.toggled,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The resting visual (fill, border, content). The wrapper paints focus and
  /// state-layer overlays on top and applies press scaling around it.
  final Widget child;

  /// Activation callback. When `null` the surface is non-interactive.
  final VoidCallback? onTap;

  /// Optional long-press callback.
  final VoidCallback? onLongPress;

  /// Clip / overlay shape. Should match the child's own corner radius so the
  /// focus ring and state layer stay concentric.
  final BorderRadius borderRadius;

  /// Haptic tier fired on activation. [TilawaHaptic.none] disables it.
  final TilawaHaptic haptic;

  /// Whether to apply the shared press-scale animation.
  final bool enablePressAnimation;

  /// Whether to paint hover/pressed/focused state-layer washes.
  final bool enableStateLayer;

  /// Overrides the focus-ring colour (defaults to [ColorScheme.primary]).
  final Color? focusColor;

  /// Base colour for state-layer washes (defaults to [ColorScheme.onSurface]).
  final Color? stateLayerColor;

  /// Accessible name. Falls back to the ambient semantics of [child] if null.
  final String? semanticLabel;

  /// Optional accessibility hint (e.g. why a control is unavailable). Mirrors
  /// [Semantics.hint].
  final String? semanticHint;

  /// Whether the surface is announced as a button (vs a generic tappable).
  final bool button;

  /// When non-null, exposes selected semantics (e.g. a selectable chip/pill).
  final bool? selected;

  /// When non-null, exposes toggle semantics (e.g. an on/off icon action such
  /// as a filter toggle). Distinct from [selected]: use [toggled] for controls
  /// that flip an independent on/off state, [selected] for single/multi-select.
  final bool? toggled;

  /// When `false`, taps are ignored and the surface is marked disabled.
  final bool enabled;

  final FocusNode? focusNode;
  final bool autofocus;

  bool get _isInteractive => enabled && (onTap != null || onLongPress != null);

  @override
  State<TilawaInteractiveSurface> createState() =>
      _TilawaInteractiveSurfaceState();
}

class _TilawaInteractiveSurfaceState extends State<TilawaInteractiveSurface> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  Offset? _pendingTapPosition;
  final ValueNotifier<bool> _pressedNotifier = ValueNotifier<bool>(false);
  final GlobalKey _childKey = GlobalKey();

  @override
  void dispose() {
    _pressedNotifier.dispose();
    super.dispose();
  }

  bool _shouldSuppressNestedInteraction(Offset localPosition) {
    final childElement = _childKey.currentContext as Element?;
    final surfaceElement = context as Element;
    final renderObject = surfaceElement.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final result = BoxHitTestResult();
    if (!renderObject.hitTest(result, position: localPosition)) {
      return false;
    }

    if (childElement == null) {
      return false;
    }

    for (final HitTestEntry entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) {
        continue;
      }

      final element = _findElementForRenderObject(surfaceElement, target);
      if (element == null || !_isDescendantOf(element, childElement)) {
        continue;
      }

      if (_isNestedInteractiveWidget(element.widget)) {
        return true;
      }
    }

    return false;
  }

  void _handlePressDown(Offset localPosition) {
    _pendingTapPosition = localPosition;
    if (_shouldSuppressNestedInteraction(localPosition)) {
      return;
    }
    _setPressed(true);
  }

  void _handlePressEnd() {
    _setPressed(false);
  }

  void _handleTapCancel() {
    _pendingTapPosition = null;
    _handlePressEnd();
  }

  void _activate() {
    if (!widget._isInteractive) return;
    final position = _pendingTapPosition;
    _pendingTapPosition = null;
    if (position != null && _shouldSuppressNestedInteraction(position)) {
      return;
    }
    TilawaInteractionFeedback.trigger(widget.haptic);
    widget.onTap?.call();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    _pressed = pressed;
    _pressedNotifier.value = pressed;
    if (!mounted) {
      return;
    }
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle) {
      setState(() {});
      return;
    }
    binding.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    if (!widget._isInteractive) {
      // Still expose semantics so a disabled surface reads correctly, but skip
      // all interaction machinery.
      return _wrapSemantics(child: widget.child, enabled: false);
    }

    final Color stateBase = widget.stateLayerColor ?? colorScheme.onSurface;
    final Color focusColor = widget.focusColor ?? colorScheme.primary;

    // State-layer wash: focused < hover < pressed, matching M3 ordering and
    // the kit's calibrated alphas. Painted as an overlay so it composites over
    // any child fill without the caller knowing.
    final double overlayAlpha = !widget.enableStateLayer
        ? 0
        : _pressed
        ? tokens.stateLayerPressed
        : _hovered
        ? tokens.stateLayerHover
        : _focused
        ? tokens.stateLayerFocused
        : 0;

    Widget surface = Stack(
      // Pass the incoming constraints straight to the resting child so the
      // wrapper stays layout-transparent: a tight cell (e.g. a fixed-height
      // grid tile) makes the child fill it, exactly as the old Material+InkWell
      // did; a loose parent lets the child size to its content.
      fit: StackFit.passthrough,
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        if (overlayAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: stateBase.withValues(alpha: overlayAlpha),
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
          ),
        // Focus ring sits above the wash so it stays visible while focused.
        if (_focused)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: focusColor,
                    width: tokens.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.enablePressAnimation) {
      surface = TilawaPressAnimation(
        pressedNotifier: _pressedNotifier,
        child: surface,
      );
    }

    surface = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget._isInteractive,
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) {
        if (!mounted) return;
        setState(() => _hovered = v);
      },
      onShowFocusHighlight: (v) {
        if (!mounted) return;
        setState(() => _focused = v);
      },
      actions: <Type, Action<Intent>>{
        if (widget.onTap != null)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
      },
      child: GestureDetector(
        // Opaque so taps on transparent padding inside the bounds still
        // register (kit GestureDetector contract — see kit_contracts_test).
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _handlePressDown(details.localPosition),
        onTapUp: (_) => _handlePressEnd(),
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap != null ? _activate : null,
        onLongPress: widget.onLongPress,
        child: surface,
      ),
    );

    return _wrapSemantics(child: surface, enabled: true);
  }

  Widget _wrapSemantics({required Widget child, required bool enabled}) {
    return Semantics(
      button: widget.button,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: child,
    );
  }
}

Element? _findElementForRenderObject(Element root, RenderObject target) {
  Element? found;
  void walk(Element element) {
    if (found != null) {
      return;
    }
    if (element.renderObject == target) {
      found = element;
      return;
    }
    element.visitChildren(walk);
  }

  walk(root);
  return found;
}

bool _isDescendantOf(Element element, Element ancestor) {
  var found = false;
  element.visitAncestorElements((Element parent) {
    if (parent == ancestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

bool _isNestedInteractiveWidget(Widget widget) {
  return switch (widget) {
    IconButton() ||
    FloatingActionButton() ||
    PopupMenuButton<Object?>() ||
    DropdownButton<Object?>() => true,
    InkWell(
      :final VoidCallback? onTap,
      :final VoidCallback? onDoubleTap,
      :final VoidCallback? onLongPress,
    )
        when onTap != null || onDoubleTap != null || onLongPress != null =>
      true,
    GestureDetector(
      :final VoidCallback? onTap,
      :final VoidCallback? onLongPress,
      :final VoidCallback? onDoubleTap,
    )
        when onTap != null || onLongPress != null || onDoubleTap != null =>
      true,
    TilawaInteractiveSurface(
      :final VoidCallback? onTap,
      :final VoidCallback? onLongPress,
    )
        when onTap != null || onLongPress != null =>
      true,
    TilawaButton(:final VoidCallback? onPressed) when onPressed != null => true,
    ListTile(:final VoidCallback? onTap, :final VoidCallback? onLongPress)
        when onTap != null || onLongPress != null =>
      true,
    _ => widget is ButtonStyleButton,
  };
}
