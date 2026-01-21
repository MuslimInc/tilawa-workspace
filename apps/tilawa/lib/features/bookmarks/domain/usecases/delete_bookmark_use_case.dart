import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../repositories/bookmarks_repository.dart';

@lazySingleton
class DeleteBookmarkUseCase {
  const DeleteBookmarkUseCase(this._repository);

  final BookmarksRepository _repository;

  Future<Either<Failure, void>> call(String id) async {
    try {
      await _repository.deleteBookmark(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
