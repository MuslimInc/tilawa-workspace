import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../../utils/price_formatter.dart';
import '../theme/quran_sessions_status_colors.dart';

/// Compact price badge for teacher list rows.
class QuranSessionPriceChip extends StatelessWidget {
  const QuranSessionPriceChip({super.key, required this.teacher});

  final QuranTeacher teacher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.quranSessionsStatus;
    final tokens = theme.tokens;
    final l10n = context.quranSessionsL10n;

    // Manual/off-app pilot price wins and is always shown as paid — never Free.
    final manualPrice = teacher.manualPaymentPrice;
    final priceLabel = manualPrice != null
        ? PriceFormatter.formatManual(manualPrice, l10n)
        : PriceFormatter.formatOrFree(
            l10n: l10n,
            pricingType: teacher.pricingType,
            price: teacher.price,
          );
    if (priceLabel.isEmpty) return const SizedBox.shrink();

    final isFree =
        manualPrice == null && teacher.pricingType == SessionPricingType.free;
    final foreground = isFree ? scheme.primary : status.scheduledForeground;

    return TilawaChip(
      label: priceLabel,
      backgroundColor: isFree
          ? scheme.primaryContainer
          : status.scheduledBackground,
      foregroundColor: foreground,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      textStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
  }
}
