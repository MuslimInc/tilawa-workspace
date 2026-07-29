import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../entities/athkar_item.dart';
import '../repositories/athkar_repository.dart';

class GetAthkarByCategoryUseCase extends UseCase<List<AthkarItem>, int> {
  GetAthkarByCategoryUseCase(this._repository);
  final AthkarRepository _repository;

  @override
  ResultFuture<List<AthkarItem>> call(int params) {
    return _repository.getAthkarByCategory(params);
  }
}
