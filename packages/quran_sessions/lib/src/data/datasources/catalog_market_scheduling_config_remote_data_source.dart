import '../datasources/market_scheduling_config_remote_data_source.dart';
import '../dtos/market_scheduling_config_dto.dart';
import '../mappers/market_scheduling_config_mapper.dart';

/// Default scheduling policy for tests and offline catalog mode.
class CatalogMarketSchedulingConfigRemoteDataSource
    implements MarketSchedulingConfigRemoteDataSource {
  const CatalogMarketSchedulingConfigRemoteDataSource();

  @override
  Future<MarketSchedulingConfigDto> getGlobal() async =>
      defaultMarketSchedulingConfigDto();

  @override
  Future<MarketSchedulingConfigDto?> getMarketOverride(
    String countryCode,
  ) async => null;
}
