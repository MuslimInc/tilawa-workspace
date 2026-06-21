import '../dtos/market_config_dto.dart';

abstract interface class MarketConfigRemoteDataSource {
  Future<MarketConfigDto> getMarketConfig(String countryCode);

  Future<List<MarketConfigDto>> getSupportedMarkets();

  Future<CityConfigDto> getCityConfig(String countryCode, String cityId);
}
