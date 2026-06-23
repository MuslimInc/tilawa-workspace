import 'package:equatable/equatable.dart';

/// Backend-neutral country entry for marketplace pickers.
///
/// Loaded via [MarketConfigRepository.getSupportedCountries]. Full pricing
/// rules live on [MarketConfig].
class MarketCountry extends Equatable {
  const MarketCountry({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.timezone,
    required this.isEnabled,
    required this.sortOrder,
    this.countryNameEn,
    this.phoneCode,
    this.flagEmoji,
  });

  /// ISO 3166-1 alpha-2, e.g. `EG`.
  final String countryCode;

  /// Primary display name (Arabic in Tilawa MVP).
  final String countryName;

  final String? countryNameEn;
  final String currencyCode;
  final String timezone;
  final String? phoneCode;
  final String? flagEmoji;
  final bool isEnabled;
  final int sortOrder;

  @override
  List<Object?> get props => [
    countryCode,
    countryName,
    countryNameEn,
    currencyCode,
    timezone,
    phoneCode,
    flagEmoji,
    isEnabled,
    sortOrder,
  ];
}
