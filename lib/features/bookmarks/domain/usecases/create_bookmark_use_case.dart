import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/bookmarks_repository.dart';

@lazySingleton
class CreateBookmarkUseCase {
  const CreateBookmarkUseCase(this._repository);

  final BookmarksRepository _repository;

  Future<Either<Failure, BookmarkEntity>> call({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int positionMs,
    required int durationMs,
    required String audioUrl,
    String? label,
    String? artworkUrl,
  }) async {
    try {
      final BookmarkEntity bookmark = await _repository.createBookmark(
        surahId: surahId,
        surahName: surahName,
        surahNameEn: surahNameEn,
        reciterId: reciterId,
        reciterName: reciterName,
        moshafId: moshafId,
        moshafName: moshafName,
        positionMs: positionMs,
        durationMs: durationMs,
        audioUrl: audioUrl,
        label: label,
        artworkUrl: artworkUrl,
      );
      return Right(bookmark);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
