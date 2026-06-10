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

/// Tier identity: icon and ambient arc variant (shared card chrome).
@immutable
class SupportTierVisual {
  const SupportTierVisual({
    required this.icon,
    required this.arcVariant,
  });

  final IconData icon;
  final SupportTierArcVariant arcVariant;
}

/// Resolves tier visuals from product id (theme-safe).
SupportTierVisual supportTierVisualFor(
  BuildContext context,
  String productId,
) {
  return switch (productId) {
    SupportProductIds.small => const SupportTierVisual(
      icon: FluentIcons.drop_24_regular,
      arcVariant: SupportTierArcVariant.light,
    ),
    SupportProductIds.kind => const SupportTierVisual(
      icon: FluentIcons.heart_24_regular,
      arcVariant: SupportTierArcVariant.balanced,
    ),
    SupportProductIds.generous => const SupportTierVisual(
      icon: FluentIcons.layer_24_regular,
      arcVariant: SupportTierArcVariant.full,
    ),
    _ => const SupportTierVisual(
      icon: FluentIcons.circle_24_regular,
      arcVariant: SupportTierArcVariant.light,
    ),
  };
}

/// Icon capsule diameter for tier cards.
double supportTierIconCapsuleSize(TilawaDesignTokens tokens) {
  return tokens.minInteractiveDimension;
}
