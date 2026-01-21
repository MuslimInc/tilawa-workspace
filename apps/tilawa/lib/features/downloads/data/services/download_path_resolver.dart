import 'package:injectable/injectable.dart';

import '../../domain/entities/download_item.dart';
import '../../utils/download_path_utils.dart';
import '../datasources/downloads_local_datasource.dart';

@LazySingleton()
class DownloadPathResolver {
  DownloadPathResolver(this._localDataSource);

  final DownloadsLocalDataSource _localDataSource;
  String? _cachedDownloadsDir;

  Future<String> getDownloadsDir() async {
    if (_cachedDownloadsDir != null) {
      return _cachedDownloadsDir!;
    }
    _cachedDownloadsDir = await _localDataSource.getDownloadsDirectory();
    return _cachedDownloadsDir!;
  }

  /// Resolves the file path for a download item dynamically.
  /// This fixes issues where absolute paths persist in DB but become invalid
  /// when the app's container path changes, while preserving the subdirectory structure.
  DownloadItem resolveDownloadPath(DownloadItem item, String downloadsDir) {
    if (item.filePath.isEmpty) {
      return item;
    }

    // Recalculate relative path to ensure structure is preserved
    final String relativePath = DownloadPathUtils.calculateRelativePath(
      item.url,
      item.reciterName,
    );
    final String resolvedPath = DownloadPathUtils.resolveFullPath(
      downloadsDir,
      relativePath,
    );

    // Only update if the path has actually changed
    if (resolvedPath != item.filePath) {
      return item.copyWith(filePath: resolvedPath);
    }
    return item;
  }
}
