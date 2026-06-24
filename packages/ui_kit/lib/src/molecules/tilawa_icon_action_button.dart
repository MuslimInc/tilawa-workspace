import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';
import '../foundation/tilawa_interactive_surface.dart';
import 'tilawa_app_bar_config.dart';

class TilawaIconActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.iconActionButton;
    final effectiveSize = size ?? componentTokens.size;
    final effectiveIconSize = iconSize ?? designTokens.iconSizeMedium;
    final effectiveBorderRadius = BorderRadius.circular(
      designTokens.resolveRadius(
        family: TilawaRadiusFamily.icon,
        width: effectiveSize,
        height: effectiveSize,
      ),
    );

    final Color iconColor = !enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final TilawaAppBarScope? appBarScope = TilawaAppBarScope.maybeOf(context);
    final Color fillColor =
        backgroundColor ??
        (appBarScope != null
            ? appBarScope.actionControlFillColor(theme.colorScheme)
            : theme.colorScheme.surface);

    // The interaction primitive owns press-scale, the focus ring, and the
    // activation haptic (light impact, matching the previous behaviour) — no
    // hand-rolled AnimationController and no Material ink ripple.
    Widget result = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: TilawaInteractiveSurface(
        onTap: onTap,
        enabled: enabled,
        toggled: toggled,
        semanticLabel: semanticLabel ?? tooltip,
        haptic: TilawaHaptic.lightImpact,
        borderRadius: effectiveBorderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: effectiveBorderRadius,
          ),
          child: Center(
            child: Icon(icon, size: effectiveIconSize, color: iconColor),
          ),
        ),
      ),
    );

    final String? tip = tooltip ?? semanticLabel;
    if (tip != null) {
      result = Tooltip(message: tip, child: result);
    }

    return result;
  }
}
