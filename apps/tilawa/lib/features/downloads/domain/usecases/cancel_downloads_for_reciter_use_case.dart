import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../data/services/batch_download_manager.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@injectable
class CancelDownloadsForReciterUseCase implements UseCase<void, String> {
  CancelDownloadsForReciterUseCase(
    this._repository,
    this._recitersRepository,
    this._batchDownloadManager,
  );

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;
  final BatchDownloadManager _batchDownloadManager;

  @override
  Future<Either<Failure, void>> call(String reciterName) async {
    try {
      // Cancel batch notifications for this reciter immediately
      // This ensures notifications are cancelled even if individual download
      // cancellation takes time
      await _batchDownloadManager.cancelBatchesForReciter(reciterName);

      // 1. Get all downloads
      final List<DownloadItem> allDownloads = await _repository
          .getAllDownloads();

      // 2. Resolve Reciter ID
      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      final int? reciterId = recitersResult.fold(
        (l) => null, // ignore failure, fallback to name
        (reciters) {
          try {
            return reciters.firstWhere((r) => r.name == reciterName).id;
          } catch (_) {
            return null;
          }
        },
      );

      // 3. Filter
      final List<DownloadItem> toCancel = [];
      for (final download in allDownloads) {
        var isMatch = false;
        if (reciterId != null && download.reciterId == reciterId) {
          isMatch = true;
        } else if (download.reciterName == reciterName) {
          isMatch = true;
        }

        if (isMatch &&
            (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.pending ||
                download.status == DownloadStatus.paused)) {
          toCancel.add(download);
        }
      }

      // 4. Cancel
      for (final download in toCancel) {
        await _repository.cancelDownload(download.id);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
