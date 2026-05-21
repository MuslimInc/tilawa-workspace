import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import '../support_tier_labels.dart';

/// Predefined one-time support tier cards with Play-formatted prices.
class SupportTierSelector extends StatelessWidget {
  const SupportTierSelector({
    super.key,
    required this.products,
    required this.selectedProductId,
    required this.onSelected,
  });

  final List<SupportProduct> products;
  final String? selectedProductId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          context.l10n.supportSelectTier,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        ...products.map(
          (SupportProduct product) => _SupportTierCard(
            product: product,
            selected: product.id == selectedProductId,
            onTap: () => onSelected(product.id),
          ),
        ),
      ],
    );
  }
}

class _SupportTierCard extends StatelessWidget {
  const _SupportTierCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final SupportProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final label = supportTierLabel(context, product.id);

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceMedium,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: tokens.borderWidthThin,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spaceExtraSmall,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      product.price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? colorScheme.onPrimaryContainer.withValues(
                                alpha: tokens.opacityEmphasis,
                              )
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: tokens.iconSizeMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
