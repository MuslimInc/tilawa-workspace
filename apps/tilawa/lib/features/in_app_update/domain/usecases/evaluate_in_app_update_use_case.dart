import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/in_app_update_action.dart';
import '../entities/in_app_update_availability.dart';
import '../entities/in_app_update_policy.dart';
import '../repositories/in_app_update_repository.dart';
import '../services/in_app_update_strategy_resolver.dart';

/// Reads remote policy and Play availability, then resolves the next action.
///
/// Does not perform update side effects — see [ExecuteInAppUpdateActionUseCase].
@lazySingleton
class EvaluateInAppUpdateUseCase {
  const EvaluateInAppUpdateUseCase(
    this._repository,
    this._strategyResolver,
  );

  final InAppUpdateRepository _repository;
  final InAppUpdateStrategyResolver _strategyResolver;

  Future<Either<Failure, InAppUpdateAction>> call() async {
    if (!await _repository.isSupported()) {
      return const Right(InAppUpdateAction.none);
    }

    final InAppUpdatePolicy policy = await _repository.getPolicy();
    final Either<Failure, InAppUpdateAvailability> availabilityResult =
        await _repository.checkAvailability();

    return availabilityResult.map(
      (InAppUpdateAvailability availability) => _strategyResolver.resolve(
        policy: policy,
        availability: availability,
      ),
    );
  }
}
