import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for downloading, managing, and loading QCF4 Quran fonts dynamically.
class QuranFontService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
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
      print('[FONT] downloadFonts: already downloaded, skipping');
      return;
    }

    final String path = await _localPath;
    final zipFile = File('$path/quran_fonts.zip');

    // 1. Download Zip
    final int tDownloadStart = DateTime.now().millisecondsSinceEpoch;
    print('[FONT] download start | url=$_fontZipUrl | t=${tDownloadStart}ms');
    var _lastLoggedPercent = -1;
    try {
      await _dio.download(
        _fontZipUrl,
        zipFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            // We use 0.0 to 0.8 for the downloading phase
            final double rawProgress = (received / total) * 0.8;
            onProgress(rawProgress);
            final int pct = (received * 100 ~/ total);
            if (pct != _lastLoggedPercent && pct % 10 == 0) {
              _lastLoggedPercent = pct;
              final int elapsed = DateTime.now().millisecondsSinceEpoch - tDownloadStart;
              final double kbps = elapsed > 0 ? (received / 1024) / (elapsed / 1000) : 0;
              print('[FONT] download $pct% | received=${(received / 1024).toStringAsFixed(0)}KB / total=${(total / 1024).toStringAsFixed(0)}KB | speed=${kbps.toStringAsFixed(0)}KB/s | elapsed=${elapsed}ms');
            }
          }
        },
      );
    } catch (e) {
      print('[FONT] download FAILED after ${DateTime.now().millisecondsSinceEpoch - tDownloadStart}ms | error=$e');
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
      throw Exception('Failed to download fonts: $e');
    }
    print('[FONT] download complete | took=${DateTime.now().millisecondsSinceEpoch - tDownloadStart}ms | zipSize=${zipFile.existsSync() ? (zipFile.lengthSync() / 1024).toStringAsFixed(0) : "?"}KB');

    // 2. Extract Zip
    if (onProgress != null) {
      onProgress(0.85); // Extraction phase started
    }
    final int tExtractStart = DateTime.now().millisecondsSinceEpoch;
    print('[FONT] extraction start | t=${tExtractStart}ms');

    try {
      final Uint8List bytes = await zipFile.readAsBytes();
      print('[FONT] zip read into memory | ${(bytes.length / 1024).toStringAsFixed(0)}KB | t=${DateTime.now().millisecondsSinceEpoch}ms');
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      print('[FONT] zip decoded | ${archive.length} entries | t=${DateTime.now().millisecondsSinceEpoch}ms');

      int extracted = 0;
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
          extracted++;
          if (extracted % 100 == 0) {
            print('[FONT] extracted $extracted files | t=${DateTime.now().millisecondsSinceEpoch}ms');
          }
        }
      }
      print('[FONT] extraction complete | $extracted files | took=${DateTime.now().millisecondsSinceEpoch - tExtractStart}ms');
    } catch (e) {
      print('[FONT] extraction FAILED after ${DateTime.now().millisecondsSinceEpoch - tExtractStart}ms | error=$e');
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

    final int tStart = DateTime.now().millisecondsSinceEpoch;
    print('[FONT] loadFontsToEngine start | t=${tStart}ms');

    final String path = await _localPath;
    final dir = Directory(path);
    if (!dir.existsSync()) {
      print('[FONT] loadFontsToEngine: fonts directory not found!');
      return;
    }

    final List<FileSystemEntity> files = dir.listSync();

    // Collect font files with their resolved family names first.
    final List<({File file, String family})> fontFiles = [];
    for (final file in files) {
      if (file is File) {
        final String filename = file.path.split('/').last;
        final String extension = filename.split('.').last.toLowerCase();
        if (!['woff', 'woff2', 'ttf'].contains(extension)) continue;

        String fontFamily;
        if (filename.startsWith('QCF4') && filename.contains('_')) {
          fontFamily = 'QCF_P${filename.substring(4, 7)}';
        } else if (filename.contains('BSML') || filename.contains('bsml')) {
          fontFamily = 'QCF_BSML';
        } else if (filename.contains('UthmanicHafs') ||
            filename.contains('uthmanic')) {
          fontFamily = 'UthmanicHafsV22';
        } else {
          fontFamily = filename.substring(0, filename.lastIndexOf('.'));
        }
        fontFiles.add((file: file, family: fontFamily));
      }
    }

    print('[FONT] loadFontsToEngine: ${fontFiles.length} fonts to register | t=${DateTime.now().millisecondsSinceEpoch}ms');

    // Phase 1 — read all font bytes in parallel (pure I/O, no engine calls).
    // This is the expensive step: 604 × ~86KB = ~52MB of disk reads.
    final int tRead = DateTime.now().millisecondsSinceEpoch;
    final List<Uint8List> allBytes = await Future.wait(
      fontFiles.map((f) => f.file.readAsBytes()),
    );
    print('[FONT] all font bytes read | took=${DateTime.now().millisecondsSinceEpoch - tRead}ms');

    // Phase 2 — register with the Flutter engine in batches to bound peak
    // memory (ByteData views don't copy, but engine registration allocates).
    const batchSize = 100;
    final List<Future<void>> loadFutures = [];
    for (var i = 0; i < fontFiles.length; i++) {
      final fontLoader = FontLoader(fontFiles[i].family);
      fontLoader.addFont(
        Future.value(ByteData.view(allBytes[i].buffer)),
      );
      loadFutures.add(fontLoader.load());
    }

    for (var i = 0; i < loadFutures.length; i += batchSize) {
      final int end =
          (i + batchSize < loadFutures.length)
              ? i + batchSize
              : loadFutures.length;
      await Future.wait(loadFutures.sublist(i, end));
      print('[FONT] registered batch ${i ~/ batchSize + 1}/${(loadFutures.length / batchSize).ceil()} (fonts ${i + 1}–$end) | elapsed=${DateTime.now().millisecondsSinceEpoch - tStart}ms');
    }

    _fontsLoadedToEngine = true;
    print('[FONT] loadFontsToEngine DONE | total=${DateTime.now().millisecondsSinceEpoch - tStart}ms');
  }

}
