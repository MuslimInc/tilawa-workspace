import 'package:injectable/injectable.dart';

import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@lazySingleton
class ToggleFavoriteReciterUseCase implements UseCase<void, int> {
  ToggleFavoriteReciterUseCase(this._repository);
  final RecitersRepository _repository;

  @override
  ResultFuture<void> call(int reciterId) {
    return _repository.toggleFavoriteReciter(reciterId);
  }
}
