import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../services/reciter_catalog_index.dart';
import 'get_reciters_use_case.dart';

@injectable
class SearchRecitersUseCase {
  SearchRecitersUseCase(this._getReciters);

  final GetRecitersUseCase _getReciters;
  ReciterCatalogIndex? _index;
  int _indexedReciterCount = -1;

  ResultFuture<List<ReciterEntity>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Right(<ReciterEntity>[]);
    }

    final Either<Failure, List<ReciterEntity>> result = await _getReciters();
    return result.map((reciters) {
      if (_index == null || _indexedReciterCount != reciters.length) {
        _index = ReciterCatalogIndex.from(reciters);
        _indexedReciterCount = reciters.length;
      }
      return _index!.search(query);
    });
  }

  /// Clears the in-memory index after language or catalog refresh.
  void invalidateIndex() {
    _index = null;
    _indexedReciterCount = -1;
  }
}
