import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../entities/bookmark_entity.dart';
import '../repositories/bookmarks_repository.dart';

@lazySingleton
class CreateBookmarkUseCase {
  CreateBookmarkUseCase(
    this._repository,
    this._appReviewTriggerManager,
  );

  final BookmarksRepository _repository;
  final AppReviewTriggerManager _appReviewTriggerManager;

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
      unawaited(
        _appReviewTriggerManager.recordSignal(AppReviewSignal.bookmarkCreated),
      );
      unawaited(
        _appReviewTriggerManager.tryPromptIfEligible(
          AppReviewPromptMoment.bookmarkCreated,
        ),
      );
      return Right(bookmark);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
