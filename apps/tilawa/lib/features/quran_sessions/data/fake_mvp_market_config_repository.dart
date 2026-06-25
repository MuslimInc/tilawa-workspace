import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
// ignore: implementation_imports
import 'package:quran_sessions/src/data/datasources/catalog_market_config_remote_data_source.dart';
// ignore: implementation_imports
import 'package:quran_sessions/src/data/repositories/market_config_repository_impl.dart';

/// Fake [MarketConfigRepository] backed by the curated [DefaultMarketCatalog].
class FakeMvpMarketConfigRepository implements MarketConfigRepository {
  FakeMvpMarketConfigRepository()
    : _impl = const MarketConfigRepositoryImpl(
        CatalogMarketConfigRemoteDataSource(),
      );

  final MarketConfigRepositoryImpl _impl;

  @override
  Future<Either<QuranSessionsFailure, List<MarketCountry>>>
  getSupportedCountries() => _impl.getSupportedCountries();

  @override
  Future<Either<QuranSessionsFailure, List<MarketCity>>> getCitiesByCountryCode(
    String countryCode,
  ) => _impl.getCitiesByCountryCode(countryCode);

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) => _impl.getMarketConfig(countryCode);

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() => _impl.getSupportedMarkets();

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) => _impl.getCityConfig(countryCode, cityId);
}
