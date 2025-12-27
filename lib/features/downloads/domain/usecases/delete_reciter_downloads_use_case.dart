import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@injectable
class DeleteReciterDownloadsUseCase {
  const DeleteReciterDownloadsUseCase(
    this._repository,
    this._recitersRepository,
  );

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;

  ResultFuture<void> call(String reciterName) async {
    try {
      // 1. Get all downloads
      final List<DownloadItem> allDownloads = await _repository
          .getAllDownloads();

      // 2. Resolve Reciter ID
      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      final int? reciterId = recitersResult.fold((l) => null, (reciters) {
        try {
          return reciters.firstWhere((r) => r.name == reciterName).id;
        } catch (_) {
          return null;
        }
      });

      // 3. Filter
      final List<DownloadItem> toDelete = [];
      for (final download in allDownloads) {
        var isMatch = false;
        if (reciterId != null && download.reciterId == reciterId) {
          isMatch = true;
        } else if (download.reciterName == reciterName) {
          isMatch = true;
        }
        if (isMatch) {
          toDelete.add(download);
        }
      }

      // 4. Delete (Cancel if needed)
      for (final download in toDelete) {
        if (download.status == DownloadStatus.downloading ||
            download.status == DownloadStatus.pending) {
          await _repository.cancelDownload(download.id);
        }
        await _repository.deleteDownload(download.id);
      }

      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
