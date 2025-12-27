import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@injectable
class GetValidCompletedDownloadsUseCase {
  GetValidCompletedDownloadsUseCase(this._repository, this._recitersRepository);

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;

  Future<Either<Failure, List<DownloadItem>>> call(String reciterName) async {
    try {
      // 1. Get all downloads
      final List<DownloadItem> allDownloads = await _repository
          .getAllDownloads();

      // 2. Resolve Reciter ID for better matching
      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      final int? reciterId = recitersResult.fold(
        (l) => null, // If failed to fetch reciters, fallback to name matching
        (reciters) {
          try {
            return reciters.firstWhere((r) => r.name == reciterName).id;
          } catch (_) {
            return null;
          }
        },
      );

      // 3. Filter and Validate
      final List<DownloadItem> validDownloads = [];

      for (final download in allDownloads) {
        // Match Reciter
        var isMatch = false;
        if (reciterId != null && download.reciterId == reciterId) {
          isMatch = true;
        } else if (download.reciterName == reciterName) {
          isMatch = true;
        }

        if (isMatch && download.status == DownloadStatus.completed) {
          final bool fileExists = await _repository.validateDownloadedFile(
            download,
          );
          if (fileExists) {
            validDownloads.add(download);
          }
        }
      }

      return Right(validDownloads);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
