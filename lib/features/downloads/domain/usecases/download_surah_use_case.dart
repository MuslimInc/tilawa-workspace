import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/single_download_repository.dart';

@Singleton()
class DownloadSurahUseCase {
  const DownloadSurahUseCase(this._repository);

  final SingleDownloadRepository _repository;

  ResultFuture<void> call({
    required String surahId,
    required String surahTitle,
    required String reciterName,
    required int reciterId,
  }) async {
    try {
      await _repository.startDownload(
        surahId,
        title: surahTitle,
        reciterName: reciterName,
        reciterId: reciterId,
        surahTitle: surahTitle,
      );
      return const Right(null);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
