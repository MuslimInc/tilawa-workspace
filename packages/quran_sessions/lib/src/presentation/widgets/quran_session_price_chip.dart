import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';
import '../theme/quran_sessions_theme.dart';

/// Compact price badge for teacher list rows.
class QuranSessionPriceChip extends StatelessWidget {
  const QuranSessionPriceChip({super.key, required this.teacher});

  final QuranTeacher teacher;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final priceLabel = PriceFormatter.formatOrFree(
      l10n: context.quranSessionsL10n,
      pricingType: teacher.pricingType,
      price: teacher.price,
    );
    if (priceLabel.isEmpty) return const SizedBox.shrink();

    final isFree = teacher.pricingType == SessionPricingType.free;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: feature.listItemGap,
      ),
      decoration: BoxDecoration(
        color: isFree
            ? feature.accentSoftBackground
            : feature.statusScheduledBackground,
        borderRadius: BorderRadius.circular(feature.chipRadius),
      ),
      child: Text(
        priceLabel,
        style: feature.priceBadgeStyle.copyWith(
          color: isFree
              ? feature.primaryColor
              : feature.statusScheduledForeground,
        ),
      ),
    );
  }
}
