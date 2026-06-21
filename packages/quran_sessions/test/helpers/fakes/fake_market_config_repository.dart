import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/data/datasources/catalog_market_config_remote_data_source.dart';
import 'package:quran_sessions/src/data/repositories/market_config_repository_impl.dart';
import 'package:quran_sessions/src/domain/entities/market_city.dart';
import 'package:quran_sessions/src/domain/entities/market_config.dart';
import 'package:quran_sessions/src/domain/entities/market_country.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/market_config_repository.dart';

class FakeMarketConfigRepository implements MarketConfigRepository {
  FakeMarketConfigRepository()
    : _impl = const MarketConfigRepositoryImpl(
        CatalogMarketConfigRemoteDataSource(),
      );

  final MarketConfigRepositoryImpl _impl;

  QuranSessionsFailure? failWith;

  /// When set, [getSupportedCountries] returns this list instead of the catalog.
  List<MarketCountry>? countriesOverride;

  /// When set, [getCitiesByCountryCode] returns the map entry for that code.
  Map<String, List<MarketCity>>? citiesOverrideByCountry;

  @override
  Future<Either<QuranSessionsFailure, List<MarketCountry>>>
  getSupportedCountries() async {
    if (failWith != null) return Left(failWith!);
    if (countriesOverride != null) return Right(countriesOverride!);
    return _impl.getSupportedCountries();
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketCity>>> getCitiesByCountryCode(
    String countryCode,
  ) async {
    if (failWith != null) return Left(failWith!);
    final override = citiesOverrideByCountry?[countryCode];
    if (override != null) return Right(override);
    return _impl.getCitiesByCountryCode(countryCode);
  }

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) async {
    if (failWith != null) return Left(failWith!);
    return _impl.getMarketConfig(countryCode);
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() async {
    if (failWith != null) return Left(failWith!);
    return _impl.getSupportedMarkets();
  }

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return _impl.getCityConfig(countryCode, cityId);
  }
}
