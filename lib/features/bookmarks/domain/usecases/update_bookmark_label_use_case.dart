import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/bookmarks_repository.dart';

@lazySingleton
class UpdateBookmarkLabelUseCase {
  const UpdateBookmarkLabelUseCase(this._repository);

  final BookmarksRepository _repository;

  Future<Either<Failure, BookmarkEntity>> call({
    required String id,
    String? label,
  }) async {
    try {
      final BookmarkEntity bookmark = await _repository.updateBookmarkLabel(
        id,
        label,
      );
      return Right(bookmark);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
