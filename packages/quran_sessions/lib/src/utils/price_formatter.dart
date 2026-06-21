import '../domain/entities/session_price.dart';
import '../domain/entities/session_pricing_type.dart';

/// Formats a [SessionPrice] for display.
///
/// Currency symbols and formatting rules are market-specific.
/// This class never performs exchange-rate conversion — it formats
/// the amount as-is in the given [SessionPrice.currencyCode].
///
/// Usage:
/// ```dart
/// Text(PriceFormatter.format(teacher.price)); // '600 ج.م. / جلسة'
/// Text(PriceFormatter.formatOrFree(teacher));  // 'مجاني' or '600 ج.م. / جلسة'
/// ```
abstract final class PriceFormatter {
  /// Formats a [SessionPrice] as a localised string.
  ///
  /// e.g. 600 EGP → '600 ج.م.'
  ///       15 USD → '15 $'
  static String format(SessionPrice price) =>
      '${_formatAmount(price.amount, price.currencyCode)} / جلسة';

  /// Returns 'مجاني' for free [pricingType], or [format] otherwise.
  ///
  /// Pass [pricingType] from [QuranTeacher.pricingType] and [price] from
  /// [QuranTeacher.price].
  static String formatOrFree({
    required SessionPricingType pricingType,
    SessionPrice? price,
  }) {
    if (pricingType == SessionPricingType.free) return 'مجاني';
    if (price == null) return '';
    return format(price);
  }

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
