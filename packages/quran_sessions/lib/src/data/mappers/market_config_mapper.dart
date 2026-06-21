import '../../domain/entities/market_config.dart';
import '../dtos/market_config_dto.dart';

extension MarketConfigDtoMapper on MarketConfigDto {
  MarketConfig toDomain() => MarketConfig(
    countryCode: countryCode,
    countryName: countryName,
    currencyCode: currencyCode,
    defaultCityId: defaultCityId,
    cities: cities.map((c) => c.toDomain()).toList(),
    isEnabled: isEnabled,
    minSessionPrice: minSessionPrice,
    maxSessionPrice: maxSessionPrice,
    platformCommissionPercent: platformCommissionPercent,
  );
}

extension CityConfigDtoMapper on CityConfigDto {
  CityConfig toDomain() => CityConfig(
    cityId: cityId,
    cityName: cityName,
    countryCode: countryCode,
    timezone: timezone,
    currencyCode: currencyCode,
    isEnabled: isEnabled,
    minSessionPrice: minSessionPrice,
    maxSessionPrice: maxSessionPrice,
  );
}
