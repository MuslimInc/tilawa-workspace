import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

class ClearFavoriteRecitersUseCase {
  const ClearFavoriteRecitersUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<void> call() {
    return _repository.clearFavoriteReciters();
  }
}
