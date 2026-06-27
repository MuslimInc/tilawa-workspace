import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../domain/entities/session_price.dart';
import '../domain/entities/session_pricing_type.dart';

/// Formats a [SessionPrice] for display.
///
/// Currency symbols and formatting rules are market-specific.
/// This class never performs exchange-rate conversion — it formats
/// the amount as-is in the given [SessionPrice.currencyCode].
abstract final class PriceFormatter {
  /// Formats a [SessionPrice] as a localised string.
  static String format(SessionPrice price, QuranSessionsLocalizations l10n) =>
      l10n.pricePerSession(_formatAmount(price.amount, price.currencyCode));

  /// Returns the free label for [pricingType], or [format] otherwise.
  static String formatOrFree({
    required SessionPricingType pricingType,
    SessionPrice? price,
    required QuranSessionsLocalizations l10n,
  }) {
    if (pricingType == SessionPricingType.free) return l10n.priceFree;
    if (price == null) return '';
    return format(price, l10n);
  }

  /// Formats [amount] with a market [currencyCode] symbol (no l10n wrapper).
  static String formatAmountOnly({
    required double amount,
    required String currencyCode,
  }) => _formatAmount(amount, currencyCode);

  static String _formatAmount(double amount, String currencyCode) {
    final symbol = _symbol(currencyCode);
    final whole = amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$whole $symbol';
  }

  static String _symbol(String currencyCode) => switch (currencyCode) {
    'EGP' => 'ج.م.',
    'SAR' => 'ر.س.',
    'AED' => 'د.إ.',
    'USD' => '\$',
    'GBP' => '£',
    'EUR' => '€',
    _ => currencyCode,
  };
}
