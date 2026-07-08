import 'package:equatable/equatable.dart';

import 'manual_payment_market_config.dart';

// ── CityConfig ────────────────────────────────────────────────────────────────

/// Configuration for a single city within a country market.
class CityConfig extends Equatable {
  const CityConfig({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.timezone,
    required this.currencyCode,
    required this.isEnabled,
    this.minSessionPrice,
    this.maxSessionPrice,
  });

  /// Stable machine ID, e.g. 'cairo', 'riyadh'.
  final String cityId;

  /// Display name in the city's primary language, e.g. 'القاهرة'.
  final String cityName;

  /// Parent market, e.g. 'EG'.
  final String countryCode;

  /// IANA timezone, e.g. 'Africa/Cairo'.
  final String timezone;

  /// ISO 4217 code, e.g. 'EGP'. May differ from country default.
  final String currencyCode;

  /// False → teachers in this city cannot accept bookings.
  final bool isEnabled;

  final double? minSessionPrice;
  final double? maxSessionPrice;

  @override
  List<Object?> get props => [
    cityId,
    cityName,
    countryCode,
    timezone,
    currencyCode,
    isEnabled,
    minSessionPrice,
    maxSessionPrice,
  ];
}

// ── MarketConfig ──────────────────────────────────────────────────────────────

/// Top-level marketplace configuration for a country.
///
/// The backend controls which markets are open and their pricing rules.
/// The app must not hardcode these values.
class MarketConfig extends Equatable {
  const MarketConfig({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.defaultCityId,
    required this.cities,
    required this.isEnabled,
    required this.minSessionPrice,
    required this.maxSessionPrice,
    required this.platformCommissionPercent,
    this.manualPayment,
  });

  /// ISO 3166-1 alpha-2 code, e.g. 'EG'.
  final String countryCode;

  /// Display name, e.g. 'مصر'.
  final String countryName;

  /// ISO 4217 default currency for this market, e.g. 'EGP'.
  final String currencyCode;

  /// cityId of the pre-selected city when the user first opens the picker.
  final String defaultCityId;

  final List<CityConfig> cities;

  /// False → the entire country market is closed; booking is blocked.
  final bool isEnabled;

  final double minSessionPrice;
  final double maxSessionPrice;

  /// Platform commission on paid sessions (0–100).
  final double platformCommissionPercent;

  /// Manual / off-app payment details for this market. Null when the market
  /// doc omits the block (callers fall back to [ManualPaymentMarketConfig]).
  final ManualPaymentMarketConfig? manualPayment;

  CityConfig? cityById(String cityId) =>
      cities.where((c) => c.cityId == cityId).firstOrNull;

  /// Active, enabled cities only.
  List<CityConfig> get enabledCities =>
      cities.where((c) => c.isEnabled).toList();

  @override
  List<Object?> get props => [
    countryCode,
    countryName,
    currencyCode,
    defaultCityId,
    cities,
    isEnabled,
    minSessionPrice,
    maxSessionPrice,
    platformCommissionPercent,
    manualPayment,
  ];
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
