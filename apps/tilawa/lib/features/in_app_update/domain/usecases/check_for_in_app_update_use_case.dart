import 'package:injectable/injectable.dart';

import '../entities/in_app_update_action.dart';
import '../entities/in_app_update_check_result.dart';
import '../entities/in_app_update_presentation_event.dart';
import '../repositories/in_app_update_repository.dart';
import '../services/in_app_update_strategy_resolver.dart';

@lazySingleton
class CheckForInAppUpdateUseCase {
  const CheckForInAppUpdateUseCase(
    this._repository,
    this._strategyResolver,
  );

  final InAppUpdateRepository _repository;
  final InAppUpdateStrategyResolver _strategyResolver;

  Future<InAppUpdateCheckResult> call() async {
    if (!await _repository.isSupported()) {
      return const InAppUpdateCheckResult();
    }

    final policy = await _repository.getPolicy();
    final availability = await _repository.checkAvailability();
    final InAppUpdateAction action = _strategyResolver.resolve(
      policy: policy,
      availability: availability,
    );

    return switch (action) {
      InAppUpdateAction.performImmediate => _performImmediate(),
      InAppUpdateAction.startFlexible => _startFlexible(),
      InAppUpdateAction.offerOptionalImmediate => const InAppUpdateCheckResult(
        presentationEvent: InAppUpdatePresentationEvent.promptOptionalImmediate,
      ),
      InAppUpdateAction.none => const InAppUpdateCheckResult(),
    };
  }

  Future<InAppUpdateCheckResult> _performImmediate() async {
    await _repository.performImmediateUpdate();
    return const InAppUpdateCheckResult();
  }

  Future<InAppUpdateCheckResult> _startFlexible() async {
    final bool started = await _repository.startFlexibleUpdate();
    if (!started) {
      return const InAppUpdateCheckResult();
    }
    return const InAppUpdateCheckResult(
      presentationEvent: InAppUpdatePresentationEvent.promptFlexibleRestart,
    );
  }
}
