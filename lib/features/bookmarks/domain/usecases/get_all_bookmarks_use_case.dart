import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/bookmarks_repository.dart';

@lazySingleton
class GetAllBookmarksUseCase {
  const GetAllBookmarksUseCase(this._repository);

  final BookmarksRepository _repository;

  Future<Either<Failure, List<BookmarkEntity>>> call() async {
    try {
      final List<BookmarkEntity> bookmarks = await _repository
          .getAllBookmarks();
      return Right(bookmarks);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
