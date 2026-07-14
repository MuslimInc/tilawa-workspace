import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../entities/forced_update_decision.dart';
import '../entities/forced_update_host_platform.dart';
import '../entities/forced_update_policy.dart';
import '../repositories/forced_update_repository.dart';
import '../services/forced_update_evaluator.dart';
import '../services/forced_update_host_platform_resolver.dart';

/// Loads remote policy + install build, then resolves [ForcedUpdateDecision].
///
/// Policy/network failures fail open to [ForcedUpdateDecision.none].
@lazySingleton
class EvaluateForcedUpdateUseCase {
  const EvaluateForcedUpdateUseCase(
    this._repository,
    this._appInfoService,
    this._evaluator,
    this._hostPlatformResolver,
  );

  final ForcedUpdateRepository _repository;
  final AppInfoService _appInfoService;
  final ForcedUpdateEvaluator _evaluator;
  final ForcedUpdateHostPlatformResolver _hostPlatformResolver;

  Future<ForcedUpdateDecision> call() async {
    try {
      final ForcedUpdatePolicy policy = await _repository.getPolicy();
      final String buildNumber =
          (await _appInfoService.getAppInfo()).buildNumber;
      final ForcedUpdateHostPlatform platform = _hostPlatformResolver.resolve();

      if (int.tryParse(buildNumber.trim()) == null) {
        logger.d(
          '[ForcedUpdate] Unparseable install build "$buildNumber" — fail open.',
        );
      }

      return _evaluator.evaluate(
        policy: policy,
        installedBuildNumber: buildNumber,
        platform: platform,
      );
    } on Object catch (e) {
      logger.d('[ForcedUpdate] Evaluate failed (fail open): $e');
      return ForcedUpdateDecision.none;
    }
  }
}
