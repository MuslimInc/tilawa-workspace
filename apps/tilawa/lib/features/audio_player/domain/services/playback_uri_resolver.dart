import 'package:injectable/injectable.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa_core/utils/url_validator.dart';

/// Resolves a network or on-disk URI for playback.
@lazySingleton
class PlaybackUriResolver {
  const PlaybackUriResolver(this._downloadsRepository);

  final DownloadsRepository _downloadsRepository;

  /// Returns a file URI when downloaded, otherwise parses [url].
  ///
  /// Throws [ArgumentError] when [url] is invalid or cannot be parsed.
  Future<Uri> resolve({
    required String url,
    String? reciterName,
  }) async {
    if (!UrlValidator.isValid(url)) {
      throw ArgumentError('Invalid audio URL: $url');
    }

    String? localFilePath;
    if (reciterName != null) {
      try {
        localFilePath = await _downloadsRepository.getDownloadedFilePath(
          url,
          reciterName,
        );
      } catch (_) {
        localFilePath = null;
      }
    }

    try {
      return localFilePath != null ? Uri.file(localFilePath) : Uri.parse(url);
    } catch (e) {
      throw ArgumentError('Failed to parse audio URI: $url');
    }
  }
}
