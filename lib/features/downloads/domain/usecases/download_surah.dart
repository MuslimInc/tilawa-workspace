import 'package:dartz/dartz.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';

class DownloadSurah {
  const DownloadSurah(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call({
    required String surahId,
    required String surahTitle,
    required String reciterName,
    required String url,
  }) async {
    try {
      await _repository.startDownload(surahId, surahTitle, reciterName, url);
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
