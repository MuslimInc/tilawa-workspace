class MarketCountryDto {
  const MarketCountryDto({
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

  final String countryCode;
  final String countryName;
  final String? countryNameEn;
  final String currencyCode;
  final String timezone;
  final String? phoneCode;
  final String? flagEmoji;
  final bool isEnabled;
  final int sortOrder;
}

class MarketCityDto {
  const MarketCityDto({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.timezone,
    required this.currencyCode,
    required this.isEnabled,
    required this.sortOrder,
    this.cityNameEn,
    this.minSessionPrice,
  });

  final String cityId;
  final String cityName;
  final String? cityNameEn;
  final String countryCode;
  final String timezone;
  final String currencyCode;
  final bool isEnabled;
  final int sortOrder;
  final double? minSessionPrice;
}
