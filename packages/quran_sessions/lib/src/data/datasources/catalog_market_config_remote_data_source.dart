import 'package:quran_sessions/src/data/dtos/market_country_dto.dart';
import 'package:quran_sessions/src/data/dtos/market_config_dto.dart';
import 'package:quran_sessions/src/data/seed/default_market_catalog.dart';
import 'package:quran_sessions/src/data/datasources/market_config_remote_data_source.dart';
import 'package:quran_sessions/src/data/exceptions/remote_exception.dart';
import 'package:quran_sessions/src/domain/entities/market_city.dart';
import 'package:quran_sessions/src/domain/entities/market_config.dart';
import 'package:quran_sessions/src/domain/entities/market_country.dart';

/// In-memory market catalog for tests and fake backend mode.
class CatalogMarketConfigRemoteDataSource
    implements MarketConfigRemoteDataSource {
  const CatalogMarketConfigRemoteDataSource();

  @override
  Future<List<MarketCountryDto>> getSupportedCountries() async =>
      DefaultMarketCatalog.enabledCountries.map(_countryToDto).toList();

  @override
  Future<List<MarketCityDto>> getCitiesByCountryCode(String countryCode) async {
    if (!_hasCountry(countryCode)) {
      throw NotFoundException('MarketCountry($countryCode)');
    }
    return DefaultMarketCatalog.enabledCitiesFor(
      countryCode,
    ).map(_cityToDto).toList();
  }

  @override
  Future<MarketConfigDto> getMarketConfig(String countryCode) async {
    if (!_hasCountry(countryCode)) {
      throw NotFoundException('MarketConfig($countryCode)');
    }
    return _marketToDto(DefaultMarketCatalog.marketConfigFor(countryCode));
  }

  @override
  Future<List<MarketConfigDto>> getSupportedMarkets() async =>
      DefaultMarketCatalog.allMarketConfigs.map(_marketToDto).toList();

  @override
  Future<MarketCityDto> getCityConfig(String countryCode, String cityId) async {
    final cities = await getCitiesByCountryCode(countryCode);
    final match = cities.where((c) => c.cityId == cityId).firstOrNull;
    if (match == null) {
      throw NotFoundException('CityConfig($countryCode/$cityId)');
    }
    return match;
  }

  bool _hasCountry(String countryCode) => DefaultMarketCatalog.countries.any(
    (c) => c.countryCode == countryCode,
  );

  MarketCountryDto _countryToDto(MarketCountry c) => MarketCountryDto(
    countryCode: c.countryCode,
    countryName: c.countryName,
    countryNameEn: c.countryNameEn,
    currencyCode: c.currencyCode,
    timezone: c.timezone,
    phoneCode: c.phoneCode,
    flagEmoji: c.flagEmoji,
    isEnabled: c.isEnabled,
    sortOrder: c.sortOrder,
  );

  MarketCityDto _cityToDto(MarketCity c) => MarketCityDto(
    cityId: c.cityId,
    cityName: c.cityName,
    cityNameEn: c.cityNameEn,
    countryCode: c.countryCode,
    timezone: c.timezone,
    currencyCode: c.currencyCode,
    isEnabled: c.isEnabled,
    sortOrder: c.sortOrder,
  );

  MarketConfigDto _marketToDto(MarketConfig m) => MarketConfigDto(
    countryCode: m.countryCode,
    countryName: m.countryName,
    currencyCode: m.currencyCode,
    defaultCityId: m.defaultCityId,
    cities: m.cities
        .map(
          (c) => CityConfigDto(
            cityId: c.cityId,
            cityName: c.cityName,
            countryCode: c.countryCode,
            timezone: c.timezone,
            currencyCode: c.currencyCode,
            isEnabled: c.isEnabled,
            minSessionPrice: c.minSessionPrice,
            maxSessionPrice: c.maxSessionPrice,
          ),
        )
        .toList(),
    isEnabled: m.isEnabled,
    minSessionPrice: m.minSessionPrice,
    maxSessionPrice: m.maxSessionPrice,
    platformCommissionPercent: m.platformCommissionPercent,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
