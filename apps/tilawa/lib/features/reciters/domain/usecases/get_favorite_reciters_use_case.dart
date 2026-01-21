import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@lazySingleton
class GetFavoriteRecitersUseCase
    implements UseCase<List<ReciterEntity>, NoParams> {
  GetFavoriteRecitersUseCase(this._repository);
  final RecitersRepository _repository;

  @override
  ResultFuture<List<ReciterEntity>> call(NoParams params) {
    return _repository.getFavoriteReciters();
  }
}
