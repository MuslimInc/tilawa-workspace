import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/booking_block_reason.dart';

/// Renders the correct booking-block message for a server-reported
/// [BookingBlockReason].
///
/// Each reason gets distinct copy + tone so the student never sees a generic
/// "payment unavailable" banner for an admin-disabled or config-missing state.
/// The backend quote is the single source of truth; this widget only maps a
/// typed reason to localized copy — it never infers the reason itself.
class BookingBlockNotice extends StatelessWidget {
  const BookingBlockNotice({super.key, required this.blockReason});

  final BookingBlockReason blockReason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    final (title, subtitle, isError) = switch (blockReason) {
      BookingBlockReason.pricingQuoteUnavailable => (
        l10n.pricingQuoteUnavailableTitle,
        l10n.pricingQuoteUnavailableSubtitle,
        false,
      ),
      BookingBlockReason.paymentProviderUnavailable => (
        l10n.bookingPaidUnavailableTitle,
        l10n.bookingPaidUnavailableSubtitle,
        true,
      ),
      BookingBlockReason.bookingDisabledByAdmin => (
        l10n.bookingDisabledByAdminTitle,
        l10n.bookingDisabledByAdminSubtitle,
        false,
      ),
      BookingBlockReason.pricingConfigMissing => (
        l10n.pricingConfigIncompleteTitle,
        l10n.pricingConfigIncompleteSubtitle,
        false,
      ),
      BookingBlockReason.marketDisabled => (
        l10n.marketDisabledBookingTitle,
        l10n.marketDisabledBookingSubtitle,
        false,
      ),
      BookingBlockReason.teacherNotBookable => (
        l10n.teacherNotBookableTitle,
        l10n.teacherNotBookableSubtitle,
        false,
      ),
      BookingBlockReason.none => ('', '', false),
    };

    final backgroundColor = isError
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foregroundColor = isError
        ? scheme.onErrorContainer
        : scheme.onSurfaceVariant;

    return TilawaCard(
      backgroundColor: backgroundColor,
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? TilawaIcons.warning : Icons.info_outline,
            size: tokens.iconSizeSmall,
            color: foregroundColor,
          ),
          SizedBox(width: tokens.spaceExtraSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
