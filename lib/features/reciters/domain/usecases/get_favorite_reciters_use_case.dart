import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/typedefs.dart';
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
