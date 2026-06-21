import 'package:dartz_plus/dartz_plus.dart';

import '../entities/market_config.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/market_config_repository.dart';

/// Returns the full [MarketConfig] for a given country code.
///
/// Used by the profile completion flow to populate city lists and
/// resolve currency / timezone after the user selects a country.
class GetMarketConfigUseCase {
  const GetMarketConfigUseCase(this._repository);

  final MarketConfigRepository _repository;

  Future<Either<QuranSessionsFailure, MarketConfig>> call(
    String countryCode,
  ) => _repository.getMarketConfig(countryCode);

  /// Convenience: returns all supported markets (for country picker).
  Future<Either<QuranSessionsFailure, List<MarketConfig>>> allMarkets() =>
      _repository.getSupportedMarkets();
}
