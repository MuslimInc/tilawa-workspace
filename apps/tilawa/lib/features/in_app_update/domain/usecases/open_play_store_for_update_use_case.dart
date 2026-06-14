import 'package:injectable/injectable.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../repositories/in_app_update_repository.dart';

@lazySingleton
class OpenPlayStoreForUpdateUseCase {
  const OpenPlayStoreForUpdateUseCase(this._repository);

  final InAppUpdateRepository _repository;

  ResultFuture<void> call() => _repository.openAppStoreListing();
}
