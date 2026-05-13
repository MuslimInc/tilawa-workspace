import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaIconActionButton extends StatefulWidget {
  const TilawaIconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.enabled = true,
    this.toggled,
    this.size,
    this.iconSize,
    this.tooltip,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  /// When `false`, the control does not accept taps and is marked disabled in
  /// the semantics tree.
  final bool enabled;

  /// When non-null, exposes a toggle semantics value (e.g. filter on/off).
  final bool? toggled;

  final double? size;
  final double? iconSize;

  /// Shown on long-press / desktop hover; also used as a11y fallback when
  /// [semanticLabel] is null.
  final String? tooltip;

  /// Screen reader label for the control.
  final String? semanticLabel;

  @override
  State<TilawaIconActionButton> createState() => _TilawaIconActionButtonState();
}

class _TilawaIconActionButtonState extends State<TilawaIconActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (!widget.enabled) {
      return;
    }
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.iconActionButton;
    final effectiveSize = widget.size ?? componentTokens.size;
    final effectiveIconSize = widget.iconSize ?? designTokens.iconSizeMedium;
    final effectiveBorderRadius = BorderRadius.circular(
      componentTokens.borderRadius,
    );

    final Color iconColor = !widget.enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : widget.isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    Widget result = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: effectiveBorderRadius,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.92).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: InkWell(
            borderRadius: effectiveBorderRadius,
            onTap: widget.enabled ? _handlePress : null,
            child: Center(
              child: Icon(
                widget.icon,
                size: effectiveIconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );

    final String? tip = widget.tooltip ?? widget.semanticLabel;
    if (tip != null) {
      result = Tooltip(message: tip, child: result);
    }

    // fix: Accessibility — explicit name for icon-only control
    return Semantics(
      button: true,
      enabled: widget.enabled,
      toggled: widget.toggled,
      label: widget.semanticLabel ?? widget.tooltip,
      child: result,
    );
  }
}
