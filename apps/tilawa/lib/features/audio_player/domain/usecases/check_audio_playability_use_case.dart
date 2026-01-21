import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/network/network_info.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../../downloads/domain/repositories/downloads_repository.dart';

/// Use case to check if an audio can be played based on network and download status.
///
/// This use case follows the Single Responsibility Principle by having one job:
/// determine if playback is allowed given the current network state and download status.
///
/// It depends on abstractions (NetworkInfo, DownloadsRepository) following the
/// Dependency Inversion Principle.
@injectable
class CheckAudioPlayabilityUseCase {
  const CheckAudioPlayabilityUseCase(
    this._networkInfo,
    this._downloadsRepository,
  );

  final NetworkInfo _networkInfo;
  final DownloadsRepository _downloadsRepository;

  /// Checks if the given audio can be played.
  ///
  /// Returns [Right(null)] if playback is allowed (either online or downloaded).
  /// Returns [Left(OfflinePlaybackFailure)] if offline and not downloaded.
  ///
  /// Logic:
  /// 1. If online → allow playback (stream from URL)
  /// 2. If offline → check if downloaded locally
  ///    - If downloaded and completed → allow playback
  ///    - If not downloaded → deny playback with failure
  Future<Either<Failure, void>> call(AudioEntity audio) async {
    try {
      // Check network connectivity
      final bool isOnline = await _networkInfo.isConnected;

      // If online, allow playback from URL
      if (isOnline) {
        return const Right(null);
      }

      // Offline - must check if downloaded
      final DownloadItem? downloadItem = await _downloadsRepository
          .getDownloadItem(audio.id);

      // No download record found
      if (downloadItem == null) {
        return const Left(
          OfflinePlaybackFailure(
            'This content is not available offline. Please download it first.',
          ),
        );
      }

      // Check if download is completed
      if (downloadItem.status == DownloadStatus.completed) {
        // Validate file still exists on disk
        final bool fileExists = await _downloadsRepository
            .validateDownloadedFile(downloadItem);

        if (fileExists) {
          return const Right(null); // Downloaded and valid
        } else {
          return const Left(
            OfflinePlaybackFailure(
              'Downloaded file is missing. Please re-download this content.',
            ),
          );
        }
      }

      // Download exists but not completed (pending, downloading, failed, etc.)
      return const Left(
        OfflinePlaybackFailure(
          'This content is not fully downloaded. Please complete the download first.',
        ),
      );
    } catch (e) {
      // Fallback for unexpected errors
      return Left(
        OfflinePlaybackFailure('Unable to verify content availability: $e'),
      );
    }
  }
}
