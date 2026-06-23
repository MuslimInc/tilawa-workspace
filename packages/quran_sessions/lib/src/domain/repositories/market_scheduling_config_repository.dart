import 'package:dartz_plus/dartz_plus.dart';

import '../entities/market_scheduling_config.dart';
import '../failures/quran_sessions_failure.dart';

/// Read-only access to platform and per-market scheduling experiment config.
abstract interface class MarketSchedulingConfigRepository {
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>> getGlobal();

  /// Market override for [countryCode], or defaults when the market has none.
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>> getForMarket(
    String countryCode,
  );
}
