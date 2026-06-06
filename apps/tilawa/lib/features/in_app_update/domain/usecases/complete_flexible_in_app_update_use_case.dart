import 'package:injectable/injectable.dart';

import '../repositories/in_app_update_repository.dart';

@lazySingleton
class CompleteFlexibleInAppUpdateUseCase {
  const CompleteFlexibleInAppUpdateUseCase(this._repository);

  final InAppUpdateRepository _repository;

  Future<void> call() => _repository.completeFlexibleUpdate();
}
