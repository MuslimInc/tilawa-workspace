import 'package:dartz/dartz.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';

class SearchReciters {
  const SearchReciters(this._repository);

  final RecitersRepository _repository;

  ResultFuture<List<ReciterEntity>> call(String query) async {
    if (query.isEmpty) {
      return Right([]);
    }
    return await _repository.searchReciters(query);
  }
}
