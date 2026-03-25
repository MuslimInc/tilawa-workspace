import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for downloading, managing, and loading QCF4 Quran fonts dynamically.
class QuranFontService {
  final Dio _dio = Dio();
  final String _fontZipUrl =
      'https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/quran_fonts.zip';
  final int _totalFonts = 604;

  static bool _fontsLoadedToEngine = false;
  static bool get hasLoadedFontsToEngine => _fontsLoadedToEngine;

  String? _fontsDirectory;

  /// Returns the local directory where fonts are stored.
  Future<String> get _localPath async {
    if (_fontsDirectory != null) return _fontsDirectory!;
    final Directory directory = await getApplicationDocumentsDirectory();
    final fontDir = Directory('${directory.path}/qcf4_fonts');
    if (!fontDir.existsSync()) {
      await fontDir.create(recursive: true);
    }
    _fontsDirectory = fontDir.path;
    return _fontsDirectory!;
  }

  /// Checks if all 604 fonts are already downloaded and extracted.
  Future<bool> areFontsDownloaded() async {
    final String path = await _localPath;
    final dir = Directory(path);
    if (!dir.existsSync()) {
      return false;
    }

    // Check if we have generally around 604 files
    final List<FileSystemEntity> files = dir.listSync();
    var woffCount = 0;
    for (final file in files) {
      if (file.path.endsWith('.woff')) {
        woffCount++;
      }
    }

    return woffCount >= _totalFonts;
  }

  /// Downloads the font zip from the server, extracts it, and saves it locally.
  Future<void> downloadFonts({Function(double)? onProgress}) async {
    if (await areFontsDownloaded()) {
      return;
    }

    final String path = await _localPath;
    final zipFile = File('$path/quran_fonts.zip');

    // 1. Download Zip
    try {
      await _dio.download(
        _fontZipUrl,
        zipFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            // We use 0.0 to 0.8 for the downloading phase
            onProgress((received / total) * 0.8);
          }
        },
      );
    } catch (e) {
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
      throw Exception('Failed to download fonts: $e');
    }

    // 2. Extract Zip
    if (onProgress != null) {
      onProgress(0.85); // Extraction phase started
    }

    try {
      final Uint8List bytes = await zipFile.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final String filename = file.name;
        if (file.isFile &&
            (filename.endsWith('.woff') ||
                filename.endsWith('.woff2') ||
                filename.endsWith('.ttf'))) {
          // Extract the filename from the path e.g. "qcf4/QCF4001_X-Regular.woff"
          final String fileBaseName = filename.split('/').last;
          final outPath = '$path/$fileBaseName';
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
    } catch (e) {
      throw Exception('Failed to extract fonts: $e');
    } finally {
      // 3. Cleanup zip
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
      if (onProgress != null) {
        onProgress(1.0); // Completed
      }
    }
  }

  /// Registers all 604 fonts with the Flutter engine so they can be used via TextStyle(fontFamily: 'QCF_Pxxx').
  /// Registers all 604 fonts with the Flutter engine.
  ///
  /// Callers must ensure fonts have already been downloaded before invoking
  /// this method (the [QuranFontLoaderBloc] guarantees this).
  Future<void> loadFontsToEngine() async {
    if (_fontsLoadedToEngine) return;

    final String path = await _localPath;
    final dir = Directory(path);
    if (!dir.existsSync()) return;

    final List<FileSystemEntity> files = dir.listSync();
    final List<Future<void>> loadFutures = [];

    for (final file in files) {
      if (file is File) {
        final String filename = file.path.split('/').last;
        final String extension = filename.split('.').last.toLowerCase();

        if (['woff', 'woff2', 'ttf'].contains(extension)) {
          // Determine font family from filename
          var fontFamily = '';

          if (filename.startsWith('QCF4') && filename.contains('_')) {
            // E.g. QCF4001_X-Regular.woff -> QCF_P001
            final String pageNumStr = filename.substring(4, 7);
            fontFamily = 'QCF_P$pageNumStr';
          } else if (filename.contains('BSML') || filename.contains('bsml')) {
            fontFamily = 'QCF_BSML';
          } else if (filename.contains('UthmanicHafs') ||
              filename.contains('uthmanic')) {
            fontFamily = 'UthmanicHafsV22';
          } else {
            // Fallback: use filename without extension
            fontFamily = filename.substring(0, filename.lastIndexOf('.'));
          }

          final fontLoader = FontLoader(fontFamily);
          fontLoader.addFont(_getFontByteData(file));
          loadFutures.add(fontLoader.load());
        }
      }
    }

    if (loadFutures.isNotEmpty) {
      await Future.wait(loadFutures);
    }

    _fontsLoadedToEngine = true;
  }

  Future<ByteData> _getFontByteData(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    return ByteData.view(bytes.buffer);
  }
}
