import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import '../support_tier_labels.dart';
import '../support_tier_visual.dart';
import 'support_tier_arc_painter.dart';

/// Premium selectable tier card with muted accent identity.
class SupportTierCard extends StatelessWidget {
  const SupportTierCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final SupportProduct product;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final SupportTierVisual visual = supportTierVisualFor(
      context,
      product.id,
    );
    final double tintAlpha = selected
        ? visual.selectedTintAlpha
        : visual.idleTintAlpha;
    final Color tint = visual.accentColor.withValues(alpha: tintAlpha);
    final Color borderColor = selected
        ? visual.accentColor.withValues(alpha: tokens.opacityEmphasis)
        : colorScheme.outlineVariant;
    final double borderWidth = selected ? 1.25 : tokens.borderWidthThin;
    final Duration duration = tokens.durationFast;
    final String label = supportTierLabel(context, product.id);
    final double capsule = supportTierIconCapsuleSize(tokens);
    final double verticalPadding = compact
        ? tokens.spaceSmall
        : tokens.spaceMedium;
    final TextDirection textDirection = Directionality.of(context);

    return Semantics(
      selected: selected,
      button: true,
      label: '$label, ${product.price}',
      child: AnimatedScale(
        scale: selected ? 1.01 : 1,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            splashColor: visual.accentColor.withValues(alpha: 0.12),
            highlightColor: visual.accentColor.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                minHeight: compact
                    ? tokens.minInteractiveDimension
                    : tokens.minInteractiveDimension + tokens.spaceLarge,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                border: Border.all(color: borderColor, width: borderWidth),
                color: Color.alphaBlend(tint, colorScheme.surface),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SupportTierArcPainter(
                          color: visual.accentColor.withValues(
                            alpha: tokens.opacitySubtle * 0.4,
                          ),
                          variant: visual.arcVariant,
                          textDirection: textDirection,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceLarge,
                        vertical: verticalPadding,
                      ),
                      child: Row(
                        children: [
                          _TierIconCapsule(
                            visual: visual,
                            selected: selected,
                            size: compact ? tokens.spaceExtraLarge : capsule,
                          ),
                          SizedBox(width: tokens.spaceMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              spacing: tokens.spaceExtraSmall,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    height: compact
                                        ? null
                                        : tokens.textHeightLoose,
                                  ),
                                ),
                                Text(
                                  product.price,
                                  style: (compact
                                          ? theme.textTheme.bodyMedium
                                          : theme.textTheme.titleMedium)
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: tokens.spaceSmall),
                          AnimatedSwitcher(
                            duration: duration,
                            child: selected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    key: const ValueKey<bool>(true),
                                    color: visual.accentColor,
                                    size: tokens.iconSizeMedium,
                                  )
                                : Icon(
                                    Icons.circle_outlined,
                                    key: const ValueKey<bool>(false),
                                    color: colorScheme.outline,
                                    size: tokens.iconSizeMedium,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TierIconCapsule extends StatelessWidget {
  const _TierIconCapsule({
    required this.visual,
    required this.selected,
    required this.size,
  });

  final SupportTierVisual visual;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double fillAlpha = selected ? 0.22 : 0.14;

    return AnimatedContainer(
      duration: tokens.durationFast,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visual.accentColor.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: visual.accentColor.withValues(
            alpha: selected ? tokens.opacityEmphasis : tokens.opacityMedium,
          ),
          width: selected ? 1.25 : tokens.borderWidthThin,
        ),
      ),
      child: Icon(
        visual.icon,
        size: tokens.iconSizeMedium,
        color: visual.accentColor,
      ),
    );
  }
}
