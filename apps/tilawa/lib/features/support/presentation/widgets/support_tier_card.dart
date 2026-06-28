import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import '../support_tier_labels.dart';
import '../support_tier_visual.dart';
import 'support_tier_arc_painter.dart';

/// Selectable support tier row with shared chrome and tier icon identity.
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
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final Brightness brightness = theme.brightness;
    final SupportTierVisual visual = supportTierVisualFor(
      context,
      product.id,
    );
    final Color cardBackground = selected
        ? Color.alphaBlend(
            colorScheme.primary.withValues(
              alpha: brightness == Brightness.dark ? 0.14 : 0.08,
            ),
            colorScheme.surface,
          )
        : colorScheme.surface;
    final Color borderColor = selected
        ? colorScheme.primary.withValues(alpha: tokens.opacityEmphasis)
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
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
              color: cardBackground,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SupportTierArcPainter(
                        color: colorScheme.primary.withValues(
                          alpha: tokens.opacitySubtle * 0.25,
                        ),
                        variant: visual.arcVariant,
                        textDirection: textDirection,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceMedium,
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
                                style:
                                    (compact
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
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          size: tokens.iconSizeMedium,
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
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: tokens.durationFast,
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: tokens.opacityEmphasis)
              : colorScheme.outlineVariant,
          width: selected ? 1.25 : tokens.borderWidthThin,
        ),
      ),
      child: Icon(
        visual.icon,
        size: tokens.iconSizeMedium,
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
