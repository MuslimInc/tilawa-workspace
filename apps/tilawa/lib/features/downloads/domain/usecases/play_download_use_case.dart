import 'package:audio_service/audio_service.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../../../shared/audio/audio_player_handler.dart';
import '../entities/download_item.dart';

@lazySingleton
class PlayDownloadUseCase implements UseCase<void, DownloadItem> {
  PlayDownloadUseCase(this._audioPlayerHandler);
  final AudioPlayerHandler _audioPlayerHandler;

  @override
  Future<Either<Failure, void>> call(DownloadItem downloadItem) async {
    try {
      final MediaItem mediaItem = _createMediaItem(downloadItem);
      await _audioPlayerHandler.updateQueue([mediaItem]);
      await _audioPlayerHandler.play();
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }

  static MediaItem _createMediaItem(DownloadItem download) {
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
  }
}
