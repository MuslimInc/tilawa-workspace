import 'package:equatable/equatable.dart';

/// Backend-neutral city entry for marketplace pickers.
///
/// Loaded via [MarketConfigRepository.getCitiesByCountryCode]. Booking
/// pricing may still resolve via [CityConfig].
class MarketCity extends Equatable {
  const MarketCity({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.timezone,
    required this.currencyCode,
    required this.isEnabled,
    required this.sortOrder,
    this.cityNameEn,
  });

  /// Stable machine id, e.g. `cairo`.
  final String cityId;

  /// Primary display name (Arabic in Tilawa MVP).
  final String cityName;

  final String? cityNameEn;
  final String countryCode;
  final String timezone;
  final String currencyCode;
  final bool isEnabled;
  final int sortOrder;

  @override
  List<Object?> get props => [
    cityId,
    cityName,
    cityNameEn,
    countryCode,
    timezone,
    currencyCode,
    isEnabled,
    sortOrder,
  ];
}
