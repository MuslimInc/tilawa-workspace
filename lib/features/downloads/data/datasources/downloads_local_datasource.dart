import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DownloadsLocalDataSource {
  Future<List<DownloadItem>> getDownloads();
  Future<void> saveDownloads(List<DownloadItem> downloads);
  Future<void> addDownload(DownloadItem download);
  Future<void> updateDownload(DownloadItem download);
  Future<void> deleteDownload(String id);
  Future<void> clearAllDownloads();
  Future<String> getDownloadsDirectory();
  Future<bool> isFileExists(String filePath);
  Future<void> deleteFile(String filePath);
}

@LazySingleton(as: DownloadsLocalDataSource)
class DownloadsLocalDataSourceImpl implements DownloadsLocalDataSource {
  static const String _downloadsKey = 'downloads';

  final SharedPreferencesAsync _prefs;

  DownloadsLocalDataSourceImpl(this._prefs);

  @override
  Future<List<DownloadItem>> getDownloads() async {
    final downloadsJson = await _prefs.getStringList(_downloadsKey) ?? [];

    return downloadsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DownloadItem.fromJson(map);
    }).toList();
  }

  @override
  Future<void> saveDownloads(List<DownloadItem> downloads) async {
    final downloadsJson = downloads
        .map((download) => jsonEncode(download.toJson()))
        .toList();
    await _prefs.setStringList(_downloadsKey, downloadsJson);
  }

  @override
  Future<void> addDownload(DownloadItem download) async {
    final downloads = await getDownloads();
    downloads.add(download);
    await saveDownloads(downloads);
  }

  @override
  Future<void> updateDownload(DownloadItem download) async {
    final downloads = await getDownloads();
    final index = downloads.indexWhere((d) => d.id == download.id);
    if (index != -1) {
      downloads[index] = download;
      await saveDownloads(downloads);
    }
  }

  @override
  Future<void> deleteDownload(String id) async {
    final downloads = await getDownloads();
    downloads.removeWhere((d) => d.id == id);
    await saveDownloads(downloads);
  }

  @override
  Future<void> clearAllDownloads() async {
    await _prefs.remove(_downloadsKey);
  }

  @override
  Future<String> getDownloadsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  @override
  Future<bool> isFileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
