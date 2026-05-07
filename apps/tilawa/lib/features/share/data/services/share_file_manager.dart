import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages temporary files created during the share flow.
///
/// All share artifacts (screenshots, audio clips) are written to a dedicated
/// temp subdirectory and cleaned up after the share sheet closes.
@lazySingleton
class ShareFileManager {
  static const _shareDirName = 'tilawa_share';
  static const _exportDirName = 'tilawa_exports';
  static const _verseCacheDirName = 'verse_cache';
  static const _maxCacheSizeBytes = 100 * 1024 * 1024; // 100 MB

  /// Returns the share temp directory, creating it if needed.
  Future<Directory> getShareDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final shareDir = Directory(p.join(tempDir.path, _shareDirName));
    if (!shareDir.existsSync()) {
      await shareDir.create(recursive: true);
    }
    return shareDir;
  }

  /// Returns the verse audio cache directory, creating it if needed.
  Future<Directory> getVerseCacheDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final cacheDir = Directory(p.join(appSupport.path, _verseCacheDirName));
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Returns the persistent export directory, creating it if needed.
  Future<Directory> getExportDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, _exportDirName));
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Saves [bytes] to a uniquely named file in the share temp directory.
  /// Returns the absolute path to the created file.
  Future<String> saveShareFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final dir = await getShareDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueName = '${timestamp}_$fileName';
    final file = File(p.join(dir.path, uniqueName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Returns the cached verse file path, or null if not cached.
  Future<String?> getCachedVersePath({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final cacheDir = await getVerseCacheDirectory();
    final fileName = _verseFileName(reciterFolder, surahNumber, ayahNumber);
    final file = File(p.join(cacheDir.path, fileName));
    if (file.existsSync()) {
      return file.path;
    }
    return null;
  }

  /// Saves a downloaded verse audio file to the cache.
  /// Returns the path to the cached file.
  Future<String> cacheVerseFile({
    required List<int> bytes,
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final cacheDir = await getVerseCacheDirectory();
    final fileName = _verseFileName(reciterFolder, surahNumber, ayahNumber);
    final file = File(p.join(cacheDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Deletes all files in the share temp directory.
  Future<void> cleanup() async {
    try {
      final dir = await getShareDirectory();
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          await entity.delete(recursive: true);
        }
      }
    } catch (_) {
      // Best-effort cleanup — do not crash.
    }
  }

  /// Deletes a single file at [path]. Silently ignores missing files.
  Future<void> deleteShareFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort deletion — do not crash.
    }
  }

  /// Copies a generated share file into persistent app storage.
  /// Returns the absolute path of the exported copy.
  Future<String> exportShareFile({
    required String sourcePath,
    String? preferredFileName,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw StateError('Source file does not exist: $sourcePath');
    }

    final exportDir = await getExportDirectory();
    final sourceName = preferredFileName ?? p.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueName = '${timestamp}_$sourceName';
    final targetPath = p.join(exportDir.path, uniqueName);

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Evicts least-recently-used verse cache files when the cache exceeds
  /// [_maxCacheSizeBytes].
  Future<void> evictVerseCacheIfNeeded() async {
    try {
      final cacheDir = await getVerseCacheDirectory();
      if (!cacheDir.existsSync()) return;

      final files = cacheDir.listSync().whereType<File>().toList()
        ..sort(
          (a, b) => a.statSync().accessed.compareTo(b.statSync().accessed),
        );

      var totalSize = files.fold<int>(0, (sum, f) => sum + f.lengthSync());

      for (final file in files) {
        if (totalSize <= _maxCacheSizeBytes) break;
        final size = file.lengthSync();
        await file.delete();
        totalSize -= size;
      }
    } catch (_) {
      // Best-effort eviction.
    }
  }

  String _verseFileName(String reciterFolder, int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '${reciterFolder}_${s}_$a.mp3';
  }
}
