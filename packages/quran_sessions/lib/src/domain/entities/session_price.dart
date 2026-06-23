import 'package:equatable/equatable.dart';

/// The market-resolved price for a single session.
///
/// Returned alongside a [QuranTeacher] once the student's country/city
/// context is known. The backend resolves the price from
/// `teachers/{id}/pricing/{marketId}` and the `quran_session_market_configs`
/// collection.
///
/// - [amount] is in [currencyCode] units. 0.0 is never used for free sessions;
///   use [SessionPricingType.free] on the teacher and leave [QuranTeacher.price]
///   null instead.
/// - [countryCode] is the ISO 3166-1 alpha-2 code of the resolved market.
/// - [cityId] is optional — some markets have city-level price overrides.
class SessionPrice extends Equatable {
  const SessionPrice({
    required this.amount,
    required this.currencyCode,
    required this.countryCode,
    this.cityId,
  });

  final double amount;

  /// ISO 4217 currency code, e.g. 'EGP', 'USD', 'SAR'.
  final String currencyCode;

  /// ISO 3166-1 alpha-2 market country code, e.g. 'EG', 'SA', 'US'.
  final String countryCode;

  /// Optional city-level granularity within the country market.
  final String? cityId;

  @override
  List<Object?> get props => [amount, currencyCode, countryCode, cityId];
}
