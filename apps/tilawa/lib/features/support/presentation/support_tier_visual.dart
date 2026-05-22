import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../domain/constants/support_product_ids.dart';

/// Decorative arc density for tier card corners.
enum SupportTierArcVariant {
  /// Single quiet arc — يسير / Light.
  light,

  /// Balanced twin arcs — كريم / Kind.
  balanced,

  /// Fuller wave — وافر / Generous.
  full,
}

/// Tier identity: muted accent, icon, and ambient arc variant.
@immutable
class SupportTierVisual {
  const SupportTierVisual({
    required this.accentColor,
    required this.icon,
    required this.arcVariant,
    required this.idleTintAlpha,
    required this.selectedTintAlpha,
  });

  final Color accentColor;
  final IconData icon;
  final SupportTierArcVariant arcVariant;

  /// Background wash when unselected.
  final double idleTintAlpha;

  /// Background wash when selected.
  final double selectedTintAlpha;
}

/// Resolves tier visuals from [ColorScheme] (theme-safe, no hard-coded hex).
SupportTierVisual supportTierVisualFor(
  BuildContext context,
  String productId,
) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final Brightness brightness = Theme.of(context).brightness;
  final double idle = brightness == Brightness.dark ? 0.10 : 0.07;
  final double selected = brightness == Brightness.dark ? 0.16 : 0.11;

  return switch (productId) {
    SupportProductIds.small => SupportTierVisual(
      accentColor: scheme.primary,
      icon: FluentIcons.drop_24_regular,
      arcVariant: SupportTierArcVariant.light,
      idleTintAlpha: idle,
      selectedTintAlpha: selected,
    ),
    SupportProductIds.kind => SupportTierVisual(
      accentColor: scheme.secondary,
      icon: FluentIcons.heart_24_regular,
      arcVariant: SupportTierArcVariant.balanced,
      idleTintAlpha: idle + 0.01,
      selectedTintAlpha: selected + 0.01,
    ),
    SupportProductIds.generous => SupportTierVisual(
      accentColor: scheme.tertiary,
      icon: FluentIcons.layer_24_regular,
      arcVariant: SupportTierArcVariant.full,
      idleTintAlpha: idle,
      selectedTintAlpha: selected,
    ),
    _ => SupportTierVisual(
      accentColor: scheme.primary,
      icon: FluentIcons.circle_24_regular,
      arcVariant: SupportTierArcVariant.light,
      idleTintAlpha: idle,
      selectedTintAlpha: selected,
    ),
  };
}

/// Icon capsule diameter for tier cards.
double supportTierIconCapsuleSize(TilawaDesignTokens tokens) {
  return tokens.minInteractiveDimension;
}
