import '../entities/market_scheduling_config.dart';
import '../repositories/market_scheduling_config_repository.dart';
import '../services/scheduling_policy_resolver.dart';

/// Resolves effective scheduling policy for a teacher's market.
class GetMarketSchedulingConfigUseCase {
  const GetMarketSchedulingConfigUseCase(
    this._repository, {
    SchedulingPolicyResolver? resolver,
  }) : _resolver = resolver ?? const SchedulingPolicyResolver();

  final MarketSchedulingConfigRepository _repository;
  final SchedulingPolicyResolver _resolver;

  Future<MarketSchedulingConfig> call({String? countryCode}) async {
    final globalResult = await _repository.getGlobal();
    final global = globalResult.fold(
      (_) => MarketSchedulingConfig.defaults,
      (value) => value,
    );

    if (countryCode == null || countryCode.isEmpty) {
      return global;
    }

    final marketResult = await _repository.getForMarket(countryCode);
    final override = marketResult.fold(
      (_) => null,
      (value) => value,
    );
    return _resolver.resolve(global: global, marketOverride: override);
  }
}
