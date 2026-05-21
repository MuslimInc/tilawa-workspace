import 'package:flutter/widgets.dart';
import 'package:tilawa/core/extensions.dart';

import '../domain/constants/support_product_ids.dart';

/// Localized display labels for Play product IDs.
String supportTierLabel(BuildContext context, String productId) {
  final l10n = context.l10n;
  return switch (productId) {
    SupportProductIds.small => l10n.supportTierSmall,
    SupportProductIds.kind => l10n.supportTierKind,
    SupportProductIds.generous => l10n.supportTierGenerous,
    _ => productId,
  };
}
