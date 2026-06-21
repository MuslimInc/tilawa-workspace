class CityConfigDto {
  const CityConfigDto({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.timezone,
    required this.currencyCode,
    required this.isEnabled,
    this.minSessionPrice,
    this.maxSessionPrice,
  });

  final String cityId;
  final String cityName;
  final String countryCode;
  final String timezone;
  final String currencyCode;
  final bool isEnabled;
  final double? minSessionPrice;
  final double? maxSessionPrice;
}

class MarketConfigDto {
  const MarketConfigDto({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.defaultCityId,
    required this.cities,
    required this.isEnabled,
    required this.minSessionPrice,
    required this.maxSessionPrice,
    required this.platformCommissionPercent,
    this.minimumStudentAgeYears,
    this.minimumTeacherAgeYears,
  });

  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String defaultCityId;
  final List<CityConfigDto> cities;
  final bool isEnabled;
  final double minSessionPrice;
  final double maxSessionPrice;
  final double platformCommissionPercent;
  final int? minimumStudentAgeYears;
  final int? minimumTeacherAgeYears;
}
