import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../repositories/pinned_athkar_repository.dart';

@lazySingleton
class SavePinnedAthkarCategoryIdsUseCase extends UseCase<void, List<int>> {
  SavePinnedAthkarCategoryIdsUseCase(this._repository);

  final PinnedAthkarRepository _repository;

  @override
  ResultVoid call(List<int> params) {
    return _repository.saveCategoryIds(params);
  }
}
