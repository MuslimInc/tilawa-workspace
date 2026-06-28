import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import 'support_tier_card.dart';

/// Grouped one-time support tiers with Play-formatted prices.
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
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMedium),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: [
          Text(
            context.l10n.supportSelectTier,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          ...products.map(
            (SupportProduct product) => SupportTierCard(
              product: product,
              selected: product.id == selectedProductId,
              onTap: () => onSelected(product.id),
            ),
          ),
        ],
      ),
    );
  }
}
