import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_pricing_quote.dart';
import '../../utils/price_formatter.dart';
import '../theme/quran_sessions_status_colors.dart';

/// Compact price badge for teacher list rows and the teacher profile header.
///
/// Renders from an explicit pricing context only:
/// - [teacher.manualPaymentPrice] (Egypt pilot) always wins and shows as paid.
/// - Otherwise [pricing] — the market-resolved quote (same source as the
///   booking screen's `getBookingPricingQuote`).
/// - When neither is available the chip renders nothing. It must never claim
///   "Free" from missing data while the booking would resolve as paid.
class QuranSessionPriceChip extends StatelessWidget {
  const QuranSessionPriceChip({
    super.key,
    required this.teacher,
    this.pricing,
  });

  final QuranTeacher teacher;

  /// Market-resolved pricing for the requesting student; null = unresolved.
  final SessionPricingQuote? pricing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.quranSessionsStatus;
    final tokens = theme.tokens;
    final l10n = context.quranSessionsL10n;

    // Manual/off-app pilot price wins and is always shown as paid — never Free.
    final manualPrice = teacher.manualPaymentPrice;
    final quote = pricing;
    final String priceLabel;
    if (manualPrice != null) {
      priceLabel = PriceFormatter.formatManual(manualPrice, l10n);
    } else if (quote != null) {
      priceLabel = PriceFormatter.formatOrFree(
        l10n: l10n,
        pricingType: quote.pricingType,
        price: quote.price,
      );
    } else {
      // Pricing not resolved for this viewer — showing nothing is honest;
      // showing "Free" here caused free-badge → paid-booking mismatches.
      return const SizedBox.shrink();
    }
    if (priceLabel.isEmpty) return const SizedBox.shrink();

    final isFree = manualPrice == null && quote != null && quote.isFree;
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
