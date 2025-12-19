import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/downloads_repository.dart';

@Singleton()
class DownloadSurahUseCase {
  const DownloadSurahUseCase(this._repository);

  final DownloadsRepository _repository;

  ResultFuture<void> call({
    required String surahId,
    required String surahTitle,
    required String reciterName,
    required int reciterId,
  }) async {
    try {
      await _repository.startDownload(
        surahId,
        surahTitle,
        reciterName,
        reciterId,
      );
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
