import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../repositories/batch_download_repository.dart';

@Singleton()
class DownloadAllSurahsUseCase {
  const DownloadAllSurahsUseCase(this._repository);

  final BatchDownloadRepository _repository;

  ResultFuture<void> call({
    required List<SurahEntity> surahs,
    required String reciterName,
    required int reciterId,
  }) async {
    try {
      final List<
        ({int reciterId, String reciterName, String surahTitle, String url})
      >
      batchItems = surahs
          .map(
            (surah) => (
              url: surah.id,
              surahTitle: surah.name,
              reciterName: reciterName,
              reciterId: reciterId,
            ),
          )
          .toList();

      await _repository.startDownloadBatch(batchItems);
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
