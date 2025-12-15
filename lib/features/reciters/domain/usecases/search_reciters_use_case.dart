import 'package:dartz_plus/dartz_plus.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/reciters_repository.dart';

class SearchRecitersUseCase {
  const SearchRecitersUseCase(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call(String query) async {
    if (query.isEmpty) {
      return const Right([]);
    }
    return _repository.searchReciters(query);
  }
}
