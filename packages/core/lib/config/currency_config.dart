/// Centralized currency configuration for the app
class CurrencyConfig {
  /// The primary currency code used throughout the app
  static const String currencyCode = 'EGP';

  /// The currency symbol to display in UI
  static const String currencySymbol = 'ج.م';

  /// The currency name for display purposes
  static const String currencyName = 'Egyptian Pound';

  /// Currency formatting configuration
  static const String locale = 'ar_EG'; // Arabic locale for Egypt

  /// Number of decimal places to show for currency
  static const int decimalPlaces = 2;

  /// Whether to show currency symbol before the amount
  static const bool symbolBeforeAmount = false;

  /// Get formatted currency string
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(decimalPlaces)} $currencySymbol';
  }

  /// Get currency symbol with amount
  static String getCurrencyDisplay(double amount) {
    if (symbolBeforeAmount) {
      return '$currencySymbol ${amount.toStringAsFixed(decimalPlaces)}';
    } else {
      return '${amount.toStringAsFixed(decimalPlaces)} $currencySymbol';
    }
  }

  /// Get currency parameters for analytics
  static Map<String, Object> getAnalyticsParams() {
    return {
      'currency': currencyCode,
      'currency_symbol': currencySymbol,
      'locale': locale,
    };
  }
}
