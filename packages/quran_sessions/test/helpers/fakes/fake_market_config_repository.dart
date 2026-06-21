import 'package:dartz_plus/dartz_plus.dart';

import '../../../lib/src/domain/entities/market_config.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/repositories/market_config_repository.dart';

class FakeMarketConfigRepository implements MarketConfigRepository {
  static final _cairo = const CityConfig(
    cityId: 'cairo',
    cityName: 'القاهرة',
    countryCode: 'EG',
    timezone: 'Africa/Cairo',
    currencyCode: 'EGP',
    isEnabled: true,
    minSessionPrice: 100,
    maxSessionPrice: 2000,
  );

  static final _egypt = MarketConfig(
    countryCode: 'EG',
    countryName: 'مصر',
    currencyCode: 'EGP',
    defaultCityId: 'cairo',
    isEnabled: true,
    minSessionPrice: 100,
    maxSessionPrice: 2000,
    platformCommissionPercent: 15,
    cities: [_cairo],
  );

  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) async {
    if (failWith != null) return Left(failWith!);
    if (countryCode == 'EG') return Right(_egypt);
    return Left(NotFoundFailure('MarketConfig($countryCode)'));
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() async {
    if (failWith != null) return Left(failWith!);
    return Right([_egypt]);
  }

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) async {
    if (failWith != null) return Left(failWith!);
    if (countryCode == 'EG' && cityId == 'cairo') return Right(_cairo);
    return Left(NotFoundFailure('CityConfig($countryCode/$cityId)'));
  }
}
