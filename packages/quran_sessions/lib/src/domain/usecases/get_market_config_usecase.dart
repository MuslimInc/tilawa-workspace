import 'package:dartz_plus/dartz_plus.dart';

import '../entities/market_city.dart';
import '../entities/market_config.dart';
import '../entities/market_country.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/market_config_repository.dart';

/// Returns marketplace configuration for profile completion and booking.
class GetMarketConfigUseCase {
  const GetMarketConfigUseCase(this._repository);

  final MarketConfigRepository _repository;

  Future<Either<QuranSessionsFailure, MarketConfig>> call(
    String countryCode,
  ) => _repository.getMarketConfig(countryCode);

  Future<Either<QuranSessionsFailure, List<MarketCountry>>>
  supportedCountries() => _repository.getSupportedCountries();

  Future<Either<QuranSessionsFailure, List<MarketCity>>> citiesByCountry(
    String countryCode,
  ) => _repository.getCitiesByCountryCode(countryCode);

  /// Legacy helper — prefer [supportedCountries] for country pickers.
  Future<Either<QuranSessionsFailure, List<MarketConfig>>> allMarkets() =>
      _repository.getSupportedMarkets();
}
