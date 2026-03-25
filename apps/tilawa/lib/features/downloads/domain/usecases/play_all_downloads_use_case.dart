import 'package:audio_service/audio_service.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../entities/download_item.dart';

@lazySingleton
class PlayAllDownloadsUseCase implements UseCase<void, PlayAllDownloadsParams> {
  PlayAllDownloadsUseCase(this._audioPlayerHandler);
  final AudioPlayerHandler _audioPlayerHandler;

  @override
  Future<Either<Failure, void>> call(PlayAllDownloadsParams params) async {
    try {
      final List<MediaItem> mediaItems = params.items.map((download) {
        final fileUri = Uri.file(download.filePath).toString();
        return MediaItem(
          id: fileUri,
          title: download.title,
          artist: download.reciterName,
          album: 'Downloaded',
          extras: {
            'isDownloaded': true,
            'localFilePath': download.filePath,
            'downloadId': download.id,
          },
        );
      }).toList();
      await _audioPlayerHandler.updateQueue(mediaItems);
      if (params.initialIndex != null) {
        await _audioPlayerHandler.skipToQueueItem(params.initialIndex!);
      }
      await _audioPlayerHandler.play();
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}

class PlayAllDownloadsParams {
  PlayAllDownloadsParams({required this.items, this.initialIndex});
  final List<DownloadItem> items;
  final int? initialIndex;
}
