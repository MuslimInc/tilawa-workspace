import '../dtos/market_config_dto.dart';
import '../dtos/market_country_dto.dart';

abstract interface class MarketConfigRemoteDataSource {
  Future<List<MarketCountryDto>> getSupportedCountries();

  Future<List<MarketCityDto>> getCitiesByCountryCode(String countryCode);

  Future<MarketConfigDto> getMarketConfig(String countryCode);

  Future<List<MarketConfigDto>> getSupportedMarkets();

  Future<MarketCityDto> getCityConfig(String countryCode, String cityId);
}
