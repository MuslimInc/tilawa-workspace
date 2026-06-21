import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/market_config.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/market_config_repository.dart';
import '../datasources/market_config_remote_data_source.dart';
import '../mappers/market_config_mapper.dart';
import 'repository_error_mapper.dart';

class MarketConfigRepositoryImpl implements MarketConfigRepository {
  const MarketConfigRepositoryImpl(this._remote);

  final MarketConfigRemoteDataSource _remote;

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
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
