import 'package:path/path.dart' as path;

const _default = 'Default';

/// Utility class for handling download file paths and structure.
class DownloadPathUtils {
  const DownloadPathUtils._();

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
        final String sanitizedReciter = _sanitizeFilename(reciterName);
        safeFileName = path.join(sanitizedReciter, pathSegments.last);
      } else {
        // Fallback
        final String sanitizedReciter = _sanitizeFilename(reciterName);
        safeFileName = path.join(sanitizedReciter, 'audio.mp3');
      }
    } catch (e) {
      final String sanitizedReciter = _sanitizeFilename(reciterName);
      safeFileName = path.join(sanitizedReciter, 'audio.mp3');
    }

    if (path.extension(safeFileName).isEmpty) {
      safeFileName = '$safeFileName.mp3';
    }

    return safeFileName;
  }

  /// Extracts narrative name from file path.
  /// Expected path format: reciterName/narrative/filename.mp3
  /// Returns narrative name or 'Default' if not found.
  static String extractNarrativeFromPath(String filePath) {
    // Normalize path separators
    final String normalizedPath = filePath.replaceAll(r'\', '/');
    final List<String> parts = normalizedPath.split('/');

    // Expected structure: .../reciterName/narrative/filename.mp3
    // We need at least 3 parts (reciter, narrative, file)
    if (parts.length >= 3) {
      // Second to last is narrative, last is filename
      final String narrative = parts[parts.length - 2];
      return narrative;
    }

    // Fallback for flat structure
    return _default;
  }

  /// Resolves the full file path dynamically by joining root dir and relative path.
  static String resolveFullPath(String downloadsDir, String relativePath) {
    final String fullPath = path.join(downloadsDir, relativePath);
    return fullPath;
  }

  /// Extracts the directory name from a file path.
  static String getDirectoryName(String filePath) {
    final String dirName = path.dirname(filePath);
    return dirName;
  }

  /// Extracts the file name from a file path.
  static String getFileName(String filePath) {
    final String fileName = path.basename(filePath);
    return fileName;
  }

  /// Sanitize filename by removing invalid characters
  static String _sanitizeFilename(String name) {
    // Determine invalid characters based on common filesystem restrictions
    // Reserved characters: < > : " / \ | ? *
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(invalidChars, '').replaceAll(' ', '_');
  }
}
