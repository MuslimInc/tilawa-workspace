import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
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

  bool _fontsLoadedToEngine = false;
  bool get hasLoadedFontsToEngine => _fontsLoadedToEngine;

  String? _fontsDirectory;
  Map<String, File>? _fontFilesByFamily;
  final Set<String> _loadedFontFamilies = <String>{};
  final Map<String, Future<void>> _inFlightFontFamilies =
      <String, Future<void>>{};
  Future<void>? _backgroundWarmUpFuture;

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
    var lastLoggedPercent = -1;
    try {
      await _dio.download(
        _fontZipUrl,
        zipFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            // We use 0.0 to 0.8 for the downloading phase
            final double rawProgress = (received / total) * 0.8;
            onProgress(rawProgress);
            final int pct = received * 100 ~/ total;
            if (pct != lastLoggedPercent && pct % 10 == 0) {
              lastLoggedPercent = pct;
              final int elapsed =
                  DateTime.now().millisecondsSinceEpoch - tDownloadStart;
              final double kbps = elapsed > 0
                  ? (received / 1024) / (elapsed / 1000)
                  : 0;
              print(
                '[FONT] download $pct% | received=${(received / 1024).toStringAsFixed(0)}KB / total=${(total / 1024).toStringAsFixed(0)}KB | speed=${kbps.toStringAsFixed(0)}KB/s | elapsed=${elapsed}ms',
              );
            }
          }
        },
      );
    } catch (e) {
      print(
        '[FONT] download FAILED after ${DateTime.now().millisecondsSinceEpoch - tDownloadStart}ms | error=$e',
      );
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
      throw Exception('Failed to download fonts: $e');
    }
    print(
      '[FONT] download complete | took=${DateTime.now().millisecondsSinceEpoch - tDownloadStart}ms | zipSize=${zipFile.existsSync() ? (zipFile.lengthSync() / 1024).toStringAsFixed(0) : "?"}KB',
    );

    // 2. Extract Zip
    if (onProgress != null) {
      onProgress(0.85); // Extraction phase started
    }
    final int tExtractStart = DateTime.now().millisecondsSinceEpoch;
    print('[FONT] extraction start | t=${tExtractStart}ms');

    try {
      final Uint8List bytes = await zipFile.readAsBytes();
      print(
        '[FONT] zip read into memory | ${(bytes.length / 1024).toStringAsFixed(0)}KB | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      print(
        '[FONT] zip decoded | ${archive.length} entries | t=${DateTime.now().millisecondsSinceEpoch}ms',
      );

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
            print(
              '[FONT] extracted $extracted files | t=${DateTime.now().millisecondsSinceEpoch}ms',
            );
          }
        }
      }
      print(
        '[FONT] extraction complete | $extracted files | took=${DateTime.now().millisecondsSinceEpoch - tExtractStart}ms',
      );
    } catch (e) {
      print(
        '[FONT] extraction FAILED after ${DateTime.now().millisecondsSinceEpoch - tExtractStart}ms | error=$e',
      );
      throw Exception('Failed to extract fonts: $e');
    } finally {
      // 3. Cleanup zip
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }
      _fontsLoadedToEngine = false;
      _fontFilesByFamily = null;
      _loadedFontFamilies.clear();
      _inFlightFontFamilies.clear();
      _backgroundWarmUpFuture = null;
      if (onProgress != null) {
        onProgress(1.0); // Completed
      }
    }
  }

  /// Loads the visible reading window first, then warms the remaining fonts in
  /// background batches so first paint is not blocked by all 604 registrations.
  Future<void> loadFontsToEngine({required int initialPageNumber}) async {
    if (_fontsLoadedToEngine) return;

    final int tStart = DateTime.now().millisecondsSinceEpoch;
    print(
      '[FONT] loadFontsToEngine start | page=$initialPageNumber | t=${tStart}ms',
    );

    final Map<String, File> fontFilesByFamily = await _getFontFilesByFamily();
    if (fontFilesByFamily.isEmpty) {
      print('[FONT] loadFontsToEngine: fonts directory not found!');
      return;
    }

    final priorityFamilies = _buildPriorityFamilies(initialPageNumber);
    print(
      '[FONT] priority families=${priorityFamilies.join(",")} | loaded=${_loadedFontFamilies.length}/${fontFilesByFamily.length}',
    );

    final int tPriority = DateTime.now().millisecondsSinceEpoch;
    await _loadFamilies(
      families: priorityFamilies,
      fontFilesByFamily: fontFilesByFamily,
      batchSize: priorityFamilies.length,
      phaseLabel: 'priority',
    );
    print(
      '[FONT] priority load done | took=${DateTime.now().millisecondsSinceEpoch - tPriority}ms',
    );

    _backgroundWarmUpFuture ??= _scheduleBackgroundWarmUp(
      fontFilesByFamily: fontFilesByFamily,
      initialPageNumber: initialPageNumber,
    );

    print(
      '[FONT] loadFontsToEngine DONE | priorityOnly=true | total=${DateTime.now().millisecondsSinceEpoch - tStart}ms',
    );
  }

  Future<Map<String, File>> _getFontFilesByFamily() async {
    if (_fontFilesByFamily != null) {
      return _fontFilesByFamily!;
    }

    final String path = await _localPath;
    final Directory dir = Directory(path);
    if (!dir.existsSync()) {
      return const <String, File>{};
    }

    final List<FileSystemEntity> files = dir.listSync();
    final Map<String, File> fontFilesByFamily = <String, File>{};

    for (final entity in files) {
      if (entity is! File) {
        continue;
      }

      final String? family = _resolvePageFontFamily(entity.path);
      if (family == null) {
        continue;
      }

      fontFilesByFamily[family] = entity;
    }

    _fontFilesByFamily = fontFilesByFamily;
    print(
      '[FONT] indexed ${fontFilesByFamily.length} page fonts | t=${DateTime.now().millisecondsSinceEpoch}ms',
    );
    return fontFilesByFamily;
  }

  String? _resolvePageFontFamily(String path) {
    final String filename = path.split('/').last;
    final String extension = filename.split('.').last.toLowerCase();
    if (!['woff', 'woff2', 'ttf'].contains(extension)) {
      return null;
    }
    if (filename.startsWith('QCF4') && filename.contains('_')) {
      return 'QCF_P${filename.substring(4, 7)}';
    }
    return null;
  }

  List<String> _buildPriorityFamilies(int initialPageNumber) {
    final Set<String> families = <String>{};
    void addPage(int pageNumber) {
      if (pageNumber < 1 || pageNumber > _totalFonts) {
        return;
      }
      families.add(_pageFamily(pageNumber));
    }

    addPage(initialPageNumber);
    addPage(initialPageNumber - 1);
    addPage(initialPageNumber + 1);

    if (initialPageNumber == 2) {
      addPage(1);
    }

    return families.toList(growable: false);
  }

  List<String> _buildBackgroundFamilies(int initialPageNumber) {
    final List<int> orderedPages =
        List<int>.generate(_totalFonts, (index) => index + 1)..sort((a, b) {
          final int distanceCompare = (a - initialPageNumber).abs().compareTo(
            (b - initialPageNumber).abs(),
          );
          if (distanceCompare != 0) {
            return distanceCompare;
          }
          return a.compareTo(b);
        });

    return orderedPages.map(_pageFamily).toList(growable: false);
  }

  String _pageFamily(int pageNumber) =>
      'QCF_P${pageNumber.toString().padLeft(3, '0')}';

  Future<void> _loadFamilies({
    required List<String> families,
    required Map<String, File> fontFilesByFamily,
    required int batchSize,
    required String phaseLabel,
    bool yieldBetweenBatches = false,
  }) async {
    final List<String> pendingFamilies = families
        .where((family) => fontFilesByFamily.containsKey(family))
        .where((family) => !_loadedFontFamilies.contains(family))
        .toList(growable: false);

    if (pendingFamilies.isEmpty) {
      print('[FONT] $phaseLabel load skipped | all requested families ready');
      return;
    }

    final int safeBatchSize = batchSize <= 0 ? 1 : batchSize;
    final int batchCount = (pendingFamilies.length / safeBatchSize).ceil();
    final int tStart = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < pendingFamilies.length; i += safeBatchSize) {
      final int end = i + safeBatchSize < pendingFamilies.length
          ? i + safeBatchSize
          : pendingFamilies.length;
      final List<String> batchFamilies = pendingFamilies.sublist(i, end);
      await Future.wait(
        batchFamilies.map(
          (family) => _ensureFontFamilyLoaded(
            family: family,
            file: fontFilesByFamily[family]!,
          ),
        ),
      );
      print(
        '[FONT] $phaseLabel batch ${i ~/ safeBatchSize + 1}/$batchCount (fonts ${i + 1}–$end) | elapsed=${DateTime.now().millisecondsSinceEpoch - tStart}ms',
      );

      if (yieldBetweenBatches && end < pendingFamilies.length) {
        await SchedulerBinding.instance.endOfFrame;
      }
    }
  }

  Future<void> _ensureFontFamilyLoaded({
    required String family,
    required File file,
  }) {
    if (_loadedFontFamilies.contains(family)) {
      return Future<void>.value();
    }

    final Future<void>? inFlight = _inFlightFontFamilies[family];
    if (inFlight != null) {
      return inFlight;
    }

    final Future<void> loadFuture = _loadFontFamily(family: family, file: file)
        .whenComplete(() {
          _inFlightFontFamilies.remove(family);
        });
    _inFlightFontFamilies[family] = loadFuture;
    return loadFuture;
  }

  Future<void> _loadFontFamily({
    required String family,
    required File file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    final FontLoader fontLoader = FontLoader(family);
    fontLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
    _loadedFontFamilies.add(family);
  }

  Future<void> _scheduleBackgroundWarmUp({
    required Map<String, File> fontFilesByFamily,
    required int initialPageNumber,
  }) async {
    await SchedulerBinding.instance.endOfFrame;
    try {
      await _loadFamilies(
        families: _buildBackgroundFamilies(initialPageNumber),
        fontFilesByFamily: fontFilesByFamily,
        batchSize: 12,
        phaseLabel: 'background',
        yieldBetweenBatches: true,
      );
      _fontsLoadedToEngine = true;
      print(
        '[FONT] background warm-up DONE | totalLoaded=${_loadedFontFamilies.length}/${fontFilesByFamily.length}',
      );
    } finally {
      _backgroundWarmUpFuture = null;
    }
  }
}
