import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'tilawa_interaction_feedback.dart';

/// The single interaction primitive for the Tilawa UI kit.
///
/// Wrapping a tappable surface in [TilawaInteractiveSurface] guarantees the
/// kit's full interaction contract in one place, so individual atoms and
/// molecules stop re-implementing (and drifting on) it:
///
/// - **Focus ring** — a visible 2 dp ring on keyboard / switch / D-pad focus,
///   drawn from [TilawaDesignTokens.focusRingWidth]. Fixes the WCAG 2.4.7
///   gap where most components had no focus state (audit UIK-005).
/// - **Press feel** — the shared scale-to-0.96 press animation via
///   [TilawaPressAnimation], so every surface presses the same way and honours
///   reduced-motion (UIK-006).
/// - **Haptics** — a single [TilawaHaptic] tier fired on activation, instead of
///   ad-hoc per-component haptics (UIK-007).
/// - **State layers** — hover / pressed / focused washes resolved from
///   [TilawaDesignTokens.stateLayerHover] / `stateLayerPressed` /
///   `stateLayerFocused` (UIK-008).
///
/// It is intentionally *unopinionated about paint*: the caller supplies the
/// resting [child] (fill, border, content). This composes existing kit pieces
/// (it does not replace [InkWell] ripple where that is the desired feel — it
/// adds the cross-cutting states a bare ripple lacks).
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
    this.button = true,
    this.selected,
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

  /// Whether the surface is announced as a button (vs a generic tappable).
  final bool button;

  /// When non-null, exposes selected semantics (e.g. a selectable chip/pill).
  final bool? selected;

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

  void _activate() {
    if (!widget._isInteractive) return;
    TilawaInteractionFeedback.trigger(widget.haptic);
    widget.onTap?.call();
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
      children: [
        widget.child,
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
      surface = TilawaPressAnimation(child: surface);
    }

    surface = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget._isInteractive,
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
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
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _activate,
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
      label: widget.semanticLabel,
      child: child,
    );
  }
}
