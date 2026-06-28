import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/manual_payment_price.dart';
import '../../utils/price_formatter.dart';
import 'manual_payment_instructions.dart';

/// Communicates that a session is paid and collected manually/off-app during
/// the Egypt pilot.
///
/// Shown wherever a teacher has a [ManualPaymentPrice]. It never implies a free
/// session and never triggers the payment provider — payment is handled off-app
/// and the booking is confirmed after payment review and teacher confirmation.
class PaidSessionNotice extends StatelessWidget {
  const PaidSessionNotice({super.key, required this.price});

  final ManualPaymentPrice price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return TilawaCard(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: tokens.iconSizeSmall,
                color: scheme.primary,
              ),
              SizedBox(width: tokens.spaceExtraSmall),
              Expanded(
                child: Text(
                  l10n.paidSessionNoticeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            PriceFormatter.formatManual(price, l10n),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          const ManualPaymentInstructions(),
          SizedBox(height: tokens.spaceSmall),
          Wrap(
            spacing: tokens.spaceExtraSmall,
            runSpacing: tokens.spaceExtraSmall,
            children: [
              TilawaMetadataChip(label: l10n.paymentMethodVodafoneCash),
              TilawaMetadataChip(label: l10n.paymentMethodInstapay),
              TilawaMetadataChip(label: l10n.paymentMethodBankTransfer),
            ],
          ),
        ],
      ),
    );
  }
}
