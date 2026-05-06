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
    final Color accent = plan.isPopular
        ? colorScheme.tertiary
        : colorScheme.primary;
    final Color surface = plan.isPopular
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.55)
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
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Text(
                      'POPULAR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onTertiary,
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
              child: FilledButton(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: plan.isPopular
                      ? colorScheme.onTertiary
                      : colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                ),
                child: Text(
                  plan.type == SubscriptionType.lifetime
                      ? 'Buy Now'
                      : 'Subscribe',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: plan.isPopular
                        ? colorScheme.onTertiary
                        : colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
