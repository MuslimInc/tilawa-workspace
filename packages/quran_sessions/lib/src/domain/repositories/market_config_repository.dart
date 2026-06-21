import 'package:dartz_plus/dartz_plus.dart';

import '../entities/market_config.dart';
import '../failures/quran_sessions_failure.dart';

/// Read-only access to marketplace configuration controlled by the backend.
///
/// The backend owns all pricing rules, enabled markets, and city configs.
/// This repository never accepts write operations — changes are made through
/// the admin backend, not the app.
abstract interface class MarketConfigRepository {
  /// Returns the market configuration for [countryCode].
  ///
  /// Returns [NotFoundFailure] if no config exists for that country.
  Future<Either<QuranSessionsFailure, MarketConfig>> getMarketConfig(
    String countryCode,
  );

  /// Returns all markets currently configured in the backend,
  /// regardless of [MarketConfig.isEnabled].
  Future<Either<QuranSessionsFailure, List<MarketConfig>>>
  getSupportedMarkets();

  /// Returns the city-level config for [cityId] within [countryCode].
  Future<Either<QuranSessionsFailure, CityConfig>> getCityConfig(
    String countryCode,
    String cityId,
  );
}
