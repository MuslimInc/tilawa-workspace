import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';
import '../services/completed_download_file_validator.dart';

@injectable
class GetValidCompletedDownloadsUseCase {
  const GetValidCompletedDownloadsUseCase(
    this._repository,
    this._recitersRepository,
    this._fileValidator,
  );

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;
  final CompletedDownloadFileValidator _fileValidator;

  Future<Either<Failure, List<DownloadItem>>> call(String reciterName) async {
    try {
      final List<DownloadItem> allDownloads =
          await _repository.getAllDownloads();

      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      final int? reciterId = recitersResult.fold(
        (_) => null,
        (List<ReciterEntity> reciters) {
          final Map<String, int> reciterIdByName = {
            for (final ReciterEntity reciter in reciters)
              reciter.name: reciter.id,
          };
          return reciterIdByName[reciterName];
        },
      );

      final List<DownloadItem> completedForReciter = allDownloads
          .where(
            (DownloadItem download) =>
                download.status == DownloadStatus.completed &&
                _matchesReciter(
                  download: download,
                  reciterName: reciterName,
                  reciterId: reciterId,
                ),
          )
          .toList(growable: false);

      final List<DownloadItem> validDownloads =
          await _fileValidator.validateExistingFiles(completedForReciter);

      return Right(validDownloads);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  bool _matchesReciter({
    required DownloadItem download,
    required String reciterName,
    required int? reciterId,
  }) {
    if (reciterId != null && download.reciterId == reciterId) {
      return true;
    }
    return download.reciterName == reciterName;
  }
}
