import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/athkar_item.dart';
import '../repositories/athkar_repository.dart';

@lazySingleton
class GetAthkarByCategoryUseCase extends UseCase<List<AthkarItem>, int> {
  GetAthkarByCategoryUseCase(this._repository);
  final AthkarRepository _repository;

  @override
  ResultFuture<List<AthkarItem>> call(int params) {
    return _repository.getAthkarByCategory(params);
  }
}
