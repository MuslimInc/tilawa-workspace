import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/market_city.dart';
import '../../domain/entities/market_config.dart';
import '../../domain/entities/market_country.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/market_config_repository.dart';
import '../datasources/market_config_remote_data_source.dart';
import '../dtos/market_country_dto.dart';
import '../mappers/market_config_mapper.dart';
import '../mappers/market_country_mapper.dart';
import 'repository_error_mapper.dart';

class MarketConfigRepositoryImpl implements MarketConfigRepository {
  const MarketConfigRepositoryImpl(this._remote);

  final MarketConfigRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, List<MarketCountry>>>
  getSupportedCountries() async {
    try {
      final dtos = await _remote.getSupportedCountries();
      if (dtos.isEmpty) {
        return const Left(MarketCatalogEmptyFailure());
      }
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketCity>>> getCitiesByCountryCode(
    String countryCode,
  ) async {
    try {
      final dtos = await _remote.getCitiesByCountryCode(countryCode);
      if (dtos.isEmpty) {
        return const Left(MarketCatalogEmptyFailure());
      }
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) async {
    try {
      final dto = await _remote.getMarketConfig(countryCode);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() async {
    try {
      final dtos = await _remote.getSupportedMarkets();
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) async {
    try {
      final dto = await _remote.getCityConfig(countryCode, cityId);
      return Right(dto.toCityConfig());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}

extension on MarketCityDto {
  CityConfig toCityConfig() => CityConfig(
    cityId: cityId,
    cityName: cityName,
    countryCode: countryCode,
    timezone: timezone,
    currencyCode: currencyCode,
    isEnabled: isEnabled,
  );
}
