import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/download_item.dart';

abstract class DownloadsLocalDataSource {
  Future<List<DownloadItem>> getDownloads();
  Future<void> saveDownloads(List<DownloadItem> downloads);
  Future<void> addDownload(DownloadItem download);
  Future<void> addDownloads(List<DownloadItem> downloads);
  Future<void> updateDownload(DownloadItem download);
  Future<void> updateDownloads(List<DownloadItem> downloads);
  Future<void> deleteDownload(String id);
  Future<void> clearAllDownloads();
  Future<String> getDownloadsDirectory();
  bool isFileExists(String filePath);
  Future<void> deleteFile(String filePath);
}

@LazySingleton(as: DownloadsLocalDataSource)
class DownloadsLocalDataSourceImpl implements DownloadsLocalDataSource {
  DownloadsLocalDataSourceImpl(this._prefs);
  static const String _downloadsKey = 'downloads';

  final SharedPreferencesAsync _prefs;
  List<DownloadItem>? _cache;

  @override
  Future<List<DownloadItem>> getDownloads() async {
    if (_cache != null) {
      return List.from(_cache!);
    }

    final List<String> downloadsJson =
        await _prefs.getStringList(_downloadsKey) ?? [];

    _cache = downloadsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DownloadItem.fromJson(map);
    }).toList();

    return List.from(_cache!);
  }

  @override
  Future<void> saveDownloads(List<DownloadItem> downloads) async {
    _cache = List.from(downloads);
    final List<String> downloadsJson = downloads
        .map((download) => jsonEncode(download.toJson()))
        .toList();
    await _prefs.setStringList(_downloadsKey, downloadsJson);
  }

  @override
  Future<void> addDownload(DownloadItem download) async {
    final List<DownloadItem> downloads = await getDownloads();
    final int index = downloads.indexWhere((d) => d.id == download.id);
    if (index != -1) {
      downloads[index] = download;
    } else {
      downloads.add(download);
    }
    await saveDownloads(downloads);
  }

  @override
  Future<void> addDownloads(List<DownloadItem> items) async {
    if (items.isEmpty) {
      return;
    }
    final List<DownloadItem> downloads = await getDownloads();
    for (final item in items) {
      final int index = downloads.indexWhere((d) => d.id == item.id);
      if (index != -1) {
        downloads[index] = item;
      } else {
        downloads.add(item);
      }
    }
    await saveDownloads(downloads);
  }

  @override
  Future<void> updateDownload(DownloadItem download) async {
    final List<DownloadItem> downloads = await getDownloads();
    final int index = downloads.indexWhere((d) => d.id == download.id);
    if (index != -1) {
      downloads[index] = download;
      await saveDownloads(downloads);
    }
  }

  @override
  Future<void> updateDownloads(List<DownloadItem> items) async {
    if (items.isEmpty) {
      return;
    }
    final List<DownloadItem> downloads = await getDownloads();
    var changed = false;
    for (final item in items) {
      final int index = downloads.indexWhere((d) => d.id == item.id);
      if (index != -1) {
        downloads[index] = item;
        changed = true;
      }
    }
    if (changed) {
      await saveDownloads(downloads);
    }
  }

  @override
  Future<void> deleteDownload(String id) async {
    final List<DownloadItem> downloads = await getDownloads();
    downloads.removeWhere((d) => d.id == id);
    await saveDownloads(downloads);
  }

  @override
  Future<void> clearAllDownloads() async {
    _cache = null;
    await _prefs.remove(_downloadsKey);
  }

  @override
  Future<String> getDownloadsDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    }

    // Fallback to application documents directory (iOS or if external storage failed)
    directory ??= await getApplicationDocumentsDirectory();

    final downloadsDir = Directory('${directory.path}/downloads');
    if (!downloadsDir.existsSync()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  @override
  bool isFileExists(String filePath) {
    final file = File(filePath);
    return file.existsSync();
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
