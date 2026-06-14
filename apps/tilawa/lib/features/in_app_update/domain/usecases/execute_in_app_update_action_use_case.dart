import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/in_app_update_action.dart';
import '../repositories/in_app_update_repository.dart';

/// Runs Play side effects for executable [InAppUpdateAction] values.
@lazySingleton
class ExecuteInAppUpdateActionUseCase {
  const ExecuteInAppUpdateActionUseCase(this._repository);

  final InAppUpdateRepository _repository;

  Future<Either<Failure, InAppUpdateAction>> call(
    InAppUpdateAction action,
  ) async {
    switch (action) {
      case InAppUpdateAction.performImmediate:
        final Either<Failure, void> result = await _repository
            .performImmediateUpdate();
        return result.map((_) => InAppUpdateAction.none);
      case InAppUpdateAction.startFlexible:
        final Either<Failure, bool> result = await _repository
            .startFlexibleUpdate();
        return result.map(
          (bool started) => started
              ? InAppUpdateAction.promptFlexibleRestart
              : InAppUpdateAction.none,
        );
      case InAppUpdateAction.promptFlexibleRestart:
      case InAppUpdateAction.offerOptionalImmediate:
        return Right(action);
      case InAppUpdateAction.none:
        return const Right(InAppUpdateAction.none);
    }
  }
}
