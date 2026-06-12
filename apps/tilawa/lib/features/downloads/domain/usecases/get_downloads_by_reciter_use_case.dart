import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../utils/download_path_utils.dart';
import '../entities/download_item.dart';
import '../repositories/downloads_repository.dart';
import '../services/completed_download_file_validator.dart';

@injectable
class GetDownloadsByReciterUseCase {
  const GetDownloadsByReciterUseCase(
    this._repository,
    this._recitersRepository,
    this._fileValidator,
  );

  final DownloadsRepository _repository;
  final RecitersRepository _recitersRepository;
  final CompletedDownloadFileValidator _fileValidator;

  Future<Either<Failure, Map<String, Map<String, List<DownloadItem>>>>>
  call() async {
    try {
      final List<DownloadItem> downloads = await _repository.getAllDownloads();

      final Either<Failure, List<ReciterEntity>> recitersResult =
          await _recitersRepository.getReciters();

      return await recitersResult.fold(
        (failure) async => Left(failure),
        (reciters) async {
          final Map<int, String> reciterNameLookup = {
            for (final ReciterEntity reciter in reciters)
              reciter.id: reciter.name,
          };
          final Map<String, Map<String, List<DownloadItem>>> grouped =
              await _groupDownloadsByReciter(downloads, reciterNameLookup);
          return Right(grouped);
        },
      );
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }

  Future<Map<String, Map<String, List<DownloadItem>>>> _groupDownloadsByReciter(
    List<DownloadItem> downloads,
    Map<int, String> reciterNameLookup,
  ) async {
    final Map<String, Map<String, List<DownloadItem>>> grouped = {};
    final List<DownloadItem> completed = downloads
        .where(
          (DownloadItem download) =>
              download.status == DownloadStatus.completed,
        )
        .toList(growable: false);

    final List<DownloadItem> validCompleted = await _fileValidator
        .validateExistingFiles(completed);

    for (final DownloadItem download in validCompleted) {
      _addDownloadToGroup(grouped, download, reciterNameLookup);
    }

    return grouped;
  }

  void _addDownloadToGroup(
    Map<String, Map<String, List<DownloadItem>>> grouped,
    DownloadItem download,
    Map<int, String> reciterNameLookup,
  ) {
    final String reciterName = download.reciterId != null
        ? (reciterNameLookup[download.reciterId] ?? download.reciterName)
        : download.reciterName;

    final String narrative = DownloadPathUtils.extractNarrativeFromPath(
      download.filePath,
    );

    grouped.putIfAbsent(reciterName, () => <String, List<DownloadItem>>{});
    grouped[reciterName]!.putIfAbsent(narrative, () => <DownloadItem>[]);
    grouped[reciterName]![narrative]!.add(download);
  }
}
