import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../utils/download_path_utils.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';

@injectable
class GetDownloadsByReciterUseCase {
  const GetDownloadsByReciterUseCase(
    this._repository,
    this._recitersRepository,
  );

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;

  Future<Either<Failure, Map<String, Map<String, List<DownloadItem>>>>>
  call() async {
    try {
      final List<DownloadItem> downloads = await _repository.getAllDownloads();

      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      return recitersResult.fold((failure) => Left(failure), (reciters) {
        final Map<int, String> reciterNameLookup = {
          for (final r in reciters) r.id: r.name,
        };
        return Right(_groupDownloadsByReciter(downloads, reciterNameLookup));
      });
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }

  Map<String, Map<String, List<DownloadItem>>> _groupDownloadsByReciter(
    List<DownloadItem> downloads,
    Map<int, String> reciterNameLookup,
  ) {
    final Map<String, Map<String, List<DownloadItem>>> grouped = {};

    for (final download in downloads) {
      // Use localized name from lookup if available, otherwise fallback to saved name
      String reciterName = download.reciterName;
      if (download.reciterId != null &&
          reciterNameLookup.containsKey(download.reciterId)) {
        reciterName = reciterNameLookup[download.reciterId!]!;
      }

      final String narrative = DownloadPathUtils.extractNarrativeFromPath(
        download.filePath,
      );

      // Ensure reciter group exists
      if (!grouped.containsKey(reciterName)) {
        grouped[reciterName] = {};
      }

      // Ensure narrative group exists within reciter
      if (!grouped[reciterName]!.containsKey(narrative)) {
        grouped[reciterName]![narrative] = [];
      }

      // Add download to appropriate narrative group
      grouped[reciterName]![narrative]!.add(download);
    }

    return grouped;
  }
}
