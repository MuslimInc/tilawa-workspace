import '../../domain/entities/market_scheduling_config.dart';
import '../datasources/market_scheduling_config_remote_data_source.dart';
import '../mappers/market_scheduling_config_mapper.dart';
import '../../domain/repositories/market_scheduling_config_repository.dart';
import 'package:dartz_plus/dartz_plus.dart';
import '../../domain/failures/quran_sessions_failure.dart';

class MarketSchedulingConfigRepositoryImpl
    implements MarketSchedulingConfigRepository {
  const MarketSchedulingConfigRepositoryImpl(this._remote);

  final MarketSchedulingConfigRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>>
  getGlobal() async {
    try {
      final dto = await _remote.getGlobal();
      return Right(marketSchedulingConfigFromDto(dto));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>> getForMarket(
    String countryCode,
  ) async {
    try {
      final override = await _remote.getMarketOverride(countryCode);
      if (override == null) {
        return Left(NotFoundFailure('MarketSchedulingConfig($countryCode)'));
      }
      return Right(marketSchedulingConfigFromDto(override));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
