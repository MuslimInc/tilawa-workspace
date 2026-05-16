import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/subscription_plan.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    // TILAWA_BRAND.md §3: Gilding (tertiary) is decorative, never a CTA color.
    // The "Popular" plan earns loudness from the badge + outlined border, not
    // from a gold subscribe button. Both plans share the Ink (primary) accent.
    final Color accent = colorScheme.primary;
    final Color surface = plan.isPopular
        ? colorScheme.primaryContainer.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerLow;

    return Card(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: plan.isPopular
              ? accent.withValues(alpha: tokens.opacityEmphasis)
              : colorScheme.outlineVariant.withValues(
                  alpha: tokens.opacityMedium,
                ),
          width: plan.isPopular ? 2 : tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: plan.isPopular ? accent : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (plan.isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceSmall,
                      vertical: tokens.spaceTiny,
                    ),
                    decoration: BoxDecoration(
                      // One-accent rule: badge keeps the same Ink family as the
                      // Subscribe CTA below it (TILAWA_BRAND.md §10).
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Text(
                      'POPULAR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              plan.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Row(
              spacing: tokens.spaceSmall,
              children: [
                Text(
                  plan.formattedPrice,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  plan.durationText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (plan.discountText.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceSmall,
                      vertical: tokens.spaceTiny,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Text(
                      plan.discountText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceLarge),
            ...plan.features.map(
              (feature) => Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceTiny),
                child: Row(
                  spacing: tokens.spaceSmall,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: tokens.iconSizeSmall,
                      color: colorScheme.primary,
                    ),
                    Expanded(
                      child: Text(feature, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            SizedBox(
              width: double.infinity,
              child: TilawaButton(
                text: plan.type == SubscriptionType.lifetime
                    ? 'Buy Now'
                    : 'Subscribe',
                variant: TilawaButtonVariant.primary,
                isFullWidth: true,
                onPressed: onSelect,
                backgroundColor: accent,
                foregroundColor: colorScheme.onPrimary,
                borderRadius: tokens.radiusMedium,
                padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
