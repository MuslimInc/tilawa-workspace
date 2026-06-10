import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';
import 'tilawa_app_bar_config.dart';

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
    this.backgroundColor,
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

  /// Optional fill colour. When `null`, uses [TilawaAppBarScope] toolbar fill
  /// inside [TilawaAppBar] / [TilawaSliverAppBar]; otherwise
  /// `ColorScheme.surface`.
  final Color? backgroundColor;

  @override
  State<TilawaIconActionButton> createState() => _TilawaIconActionButtonState();
}

class _TilawaIconActionButtonState extends State<TilawaIconActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Press animation honours the kit's motion budget. Read from theme here —
    // initState can't, but didChangeDependencies fires before the first build
    // and again on theme/locale changes, so the controller always matches the
    // current durationMedium token.
    _animationController.duration = Theme.of(context).tokens.durationMedium;
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
    TilawaInteractionFeedback.trigger(TilawaHaptic.lightImpact);
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
      designTokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: effectiveSize,
      ),
    );

    final Color iconColor = !widget.enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : widget.isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final TilawaAppBarScope? appBarScope = TilawaAppBarScope.maybeOf(context);
    final Color fillColor =
        widget.backgroundColor ??
        (appBarScope != null
            ? appBarScope.actionControlFillColor(theme.colorScheme)
            : theme.colorScheme.surface);

    Widget result = Container(
      margin: EdgeInsets.symmetric(horizontal: designTokens.spaceExtraSmall),
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: fillColor,
        borderRadius: effectiveBorderRadius,
        child: ScaleTransition(
          scale:
              Tween<double>(
                begin: 1.0,
                end: TilawaInteractionFeedback.pressScaleEnd,
              ).animate(
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
