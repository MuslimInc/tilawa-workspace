import '../dtos/market_scheduling_config_dto.dart';

abstract interface class MarketSchedulingConfigRemoteDataSource {
  Future<MarketSchedulingConfigDto> getGlobal();

  Future<MarketSchedulingConfigDto?> getMarketOverride(String countryCode);
}
