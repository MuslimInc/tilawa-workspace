import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/history_entity.dart';

abstract class HistoryLocalDataSource {
  Future<List<HistoryEntity>> getAllHistory();
  Future<HistoryEntity?> getHistoryById(String id);
  Future<HistoryEntity?> getHistoryByKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  });
  Future<void> saveHistory(HistoryEntity history);
  Future<void> deleteHistory(String id);
  Future<void> saveAllHistory(List<HistoryEntity> historyList);
  Future<void> clearAllHistory();
  Future<String> generateHistoryId();
  Future<int> getHistoryCount();
}

@LazySingleton(as: HistoryLocalDataSource)
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(this._prefs);

  static const String _historyKey = 'listening_history';
  static const String _historyCounterKey = 'history_counter';
  static const int _maxHistorySize = 500; // Limit history entries

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<HistoryEntity>> getAllHistory() async {
    final List<String> historyJson =
        await _prefs.getStringList(_historyKey) ?? [];

    final List<HistoryEntity> history = historyJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return HistoryEntity.fromJson(map);
    }).toList();

    // Sort by played date (newest first)
    history.sort((a, b) => b.playedAt.compareTo(a.playedAt));

    return history;
  }

  @override
  Future<HistoryEntity?> getHistoryById(String id) async {
    final List<HistoryEntity> history = await getAllHistory();
    try {
      return history.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<HistoryEntity?> getHistoryByKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async {
    final List<HistoryEntity> history = await getAllHistory();
    try {
      return history.firstWhere(
        (h) =>
            h.surahId == surahId &&
            h.reciterId == reciterId &&
            h.moshafId == moshafId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveHistory(HistoryEntity history) async {
    final List<HistoryEntity> historyList = await getAllHistory();

    final int existingIndex = historyList.indexWhere((h) => h.id == history.id);

    if (existingIndex != -1) {
      historyList[existingIndex] = history;
    } else {
      historyList.insert(0, history); // Add to beginning
    }

    // Trim history if it exceeds max size
    final List<HistoryEntity> trimmedHistory =
        historyList.length > _maxHistorySize
        ? historyList.sublist(0, _maxHistorySize)
        : historyList;

    await saveAllHistory(trimmedHistory);
  }

  @override
  Future<void> deleteHistory(String id) async {
    final List<HistoryEntity> history = await getAllHistory();
    history.removeWhere((h) => h.id == id);
    await saveAllHistory(history);
  }

  @override
  Future<void> saveAllHistory(List<HistoryEntity> historyList) async {
    final List<String> historyJson = historyList
        .map((h) => jsonEncode(h.toJson()))
        .toList();
    await _prefs.setStringList(_historyKey, historyJson);
  }

  @override
  Future<void> clearAllHistory() async {
    await _prefs.remove(_historyKey);
    await _prefs.remove(_historyCounterKey);
  }

  @override
  Future<String> generateHistoryId() async {
    final int counter = await _prefs.getInt(_historyCounterKey) ?? 0;
    final int newCounter = counter + 1;
    await _prefs.setInt(_historyCounterKey, newCounter);
    return 'history_$newCounter';
  }

  @override
  Future<int> getHistoryCount() async {
    final List<HistoryEntity> history = await getAllHistory();
    return history.length;
  }
}
