import 'package:injectable/injectable.dart';

import '../repositories/in_app_update_repository.dart';

@lazySingleton
class PerformImmediateInAppUpdateUseCase {
  const PerformImmediateInAppUpdateUseCase(this._repository);

  final InAppUpdateRepository _repository;

  Future<void> call() => _repository.performImmediateUpdate();
}
