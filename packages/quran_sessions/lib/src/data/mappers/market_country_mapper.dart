import '../../domain/entities/market_city.dart';
import '../../domain/entities/market_country.dart';
import '../dtos/market_country_dto.dart';

extension MarketCountryDtoMapper on MarketCountryDto {
  MarketCountry toDomain() => MarketCountry(
    countryCode: countryCode,
    countryName: countryName,
    countryNameEn: countryNameEn,
    currencyCode: currencyCode,
    timezone: timezone,
    phoneCode: phoneCode,
    flagEmoji: flagEmoji,
    isEnabled: isEnabled,
    sortOrder: sortOrder,
  );
}

extension MarketCityDtoMapper on MarketCityDto {
  MarketCity toDomain() => MarketCity(
    cityId: cityId,
    cityName: cityName,
    cityNameEn: cityNameEn,
    countryCode: countryCode,
    timezone: timezone,
    currencyCode: currencyCode,
    isEnabled: isEnabled,
    sortOrder: sortOrder,
  );
}
