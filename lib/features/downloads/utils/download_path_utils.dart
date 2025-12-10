import 'package:path/path.dart' as path;

import '../../../main.dart';

const _default = 'Default';

/// Utility class for handling download file paths and structure.
class DownloadPathUtils {
  /// Calculates the relative file path based on URL and reciter name.
  /// This preserves the directory structure (reciter/narrative/file.mp3).
  static String calculateRelativePath(String url, String reciterName) {
    final String trimmedUrl = url.trim();
    String safeFileName;

    try {
      final Uri parsed = Uri.parse(trimmedUrl);
      final List<String> pathSegments = parsed.pathSegments;

      if (pathSegments.length >= 2) {
        // URL has folder structure and filename: reciter/narrative/file.mp3
        safeFileName = path.joinAll(pathSegments);
      } else if (pathSegments.isNotEmpty) {
        // URL only has filename, create folder from reciter name
        final String sanitizedReciter = reciterName.replaceAll(' ', '_');
        safeFileName = path.join(sanitizedReciter, pathSegments.last);
      } else {
        // Fallback
        final String sanitizedReciter = reciterName.replaceAll(' ', '_');
        safeFileName = path.join(sanitizedReciter, 'audio.mp3');
        logger.d(
          '[DownloadPathUtils] URL has no path segments or is invalid. Using fallback: $url -> $safeFileName',
        );
      }
    } catch (e) {
      final String sanitizedReciter = reciterName.replaceAll(' ', '_');
      safeFileName = path.join(sanitizedReciter, 'audio.mp3');
      logger.w(
        '[DownloadPathUtils] Error parsing URL: $url. Using fallback: $safeFileName. Error: $e',
      );
    }

    if (path.extension(safeFileName).isEmpty) {
      safeFileName = '$safeFileName.mp3';
      logger.d(
        '[DownloadPathUtils] Added missing .mp3 extension: $safeFileName',
      );
    }

    logger.d('[DownloadPathUtils] Calculated relative path: $safeFileName');
    return safeFileName;
  }

  /// Extracts narrative name from file path.
  /// Expected path format: reciterName/narrative/filename.mp3
  /// Returns narrative name or 'Default' if not found.
  static String extractNarrativeFromPath(String filePath) {
    try {
      // Normalize path separators
      final String normalizedPath = filePath.replaceAll(r'\', '/');
      final List<String> parts = normalizedPath.split('/');

      // Expected structure: .../reciterName/narrative/filename.mp3
      // We need at least 3 parts (reciter, narrative, file)
      if (parts.length >= 3) {
        // Second to last is narrative, last is filename
        final String narrative = parts[parts.length - 2];
        logger.d(
          '[DownloadPathUtils] Extracted narrative: $narrative from $filePath',
        );
        return narrative;
      }

      // Fallback for flat structure
      logger.d(
        '[DownloadPathUtils] Could not extract narrative from flat path: $filePath. Using default.',
      );
      return _default;
    } catch (e) {
      logger.d(
        '[DownloadPathUtils] Error extracting narrative from path: $filePath. Using default. Error: $e',
      );
      return _default;
    }
  }

  /// Resolves the full file path dynamically by joining root dir and relative path.
  static String resolveFullPath(String downloadsDir, String relativePath) {
    final String fullPath = path.join(downloadsDir, relativePath);
    logger.d('[DownloadPathUtils] Resolved full path: $fullPath');
    return fullPath;
  }

  /// Extracts the directory name from a file path.
  static String getDirectoryName(String filePath) {
    final String dirName = path.dirname(filePath);
    logger.d('[DownloadPathUtils] Extracted directory name: $dirName');
    return dirName;
  }

  /// Extracts the file name from a file path.
  static String getFileName(String filePath) {
    final String fileName = path.basename(filePath);
    logger.d('[DownloadPathUtils] Extracted file name: $fileName');
    return fileName;
  }
}
