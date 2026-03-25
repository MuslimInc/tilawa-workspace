import 'package:injectable/injectable.dart';

import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

@lazySingleton
class ClearFavoriteRecitersUseCase {
  const ClearFavoriteRecitersUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<void> call() {
    return _repository.clearFavoriteReciters();
  }
}
