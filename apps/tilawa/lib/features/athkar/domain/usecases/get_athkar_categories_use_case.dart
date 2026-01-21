import 'package:injectable/injectable.dart';

import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/athkar_category.dart';
import '../repositories/athkar_repository.dart';

@lazySingleton
class GetAthkarCategoriesUseCase
    extends UseCase<List<AthkarCategory>, NoParams> {
  GetAthkarCategoriesUseCase(this._repository);
  final AthkarRepository _repository;

  @override
  ResultFuture<List<AthkarCategory>> call(NoParams params) {
    return _repository.getCategories();
  }
}
