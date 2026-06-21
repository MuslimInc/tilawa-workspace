import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// MVP implementation of [MarketConfigRepository] backed by hard-coded data.
///
/// MVP ships with Egypt only. Additional markets are added by the backend
/// by writing to `quran_session_market_configs/{countryCode}` in Firestore
/// — the app never hard-codes market decisions.
///
/// EGP is Egypt's currency. Do NOT treat EGP as a global default;
/// it is specific to the Egypt market configuration.
class FakeMvpMarketConfigRepository implements MarketConfigRepository {
  static final _egypt = MarketConfig(
    countryCode: 'EG',
    countryName: 'مصر',
    currencyCode: 'EGP',
    defaultCityId: 'cairo',
    isEnabled: true,
    minSessionPrice: 100,
    maxSessionPrice: 2000,
    platformCommissionPercent: 15,
    cities: [
      const CityConfig(
        cityId: 'cairo',
        cityName: 'القاهرة',
        countryCode: 'EG',
        timezone: 'Africa/Cairo',
        currencyCode: 'EGP',
        isEnabled: true,
        minSessionPrice: 100,
        maxSessionPrice: 2000,
      ),
      const CityConfig(
        cityId: 'alexandria',
        cityName: 'الإسكندرية',
        countryCode: 'EG',
        timezone: 'Africa/Cairo',
        currencyCode: 'EGP',
        isEnabled: true,
        minSessionPrice: 100,
        maxSessionPrice: 1500,
      ),
      const CityConfig(
        cityId: 'giza',
        cityName: 'الجيزة',
        countryCode: 'EG',
        timezone: 'Africa/Cairo',
        currencyCode: 'EGP',
        isEnabled: true,
        minSessionPrice: 100,
        maxSessionPrice: 2000,
      ),
    ],
  );

  static final _allMarkets = [_egypt];

  @override
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  ) async {
    final market = _allMarkets
        .where((m) => m.countryCode == countryCode)
        .firstOrNull;
    if (market == null) {
      return Left(NotFoundFailure('MarketConfig($countryCode)'));
    }
    return Right(market);
  }

  @override
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets() async => Right(_allMarkets);

  @override
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  ) async {
    final market = _allMarkets
        .where((m) => m.countryCode == countryCode)
        .firstOrNull;
    if (market == null) {
      return Left(NotFoundFailure('MarketConfig($countryCode)'));
    }
    final city = market.cityById(cityId);
    if (city == null) {
      return Left(NotFoundFailure('CityConfig($countryCode/$cityId)'));
    }
    return Right(city);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
