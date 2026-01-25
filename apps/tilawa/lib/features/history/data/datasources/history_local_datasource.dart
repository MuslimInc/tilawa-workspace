import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/history_entity.dart';

abstract class HistoryLocalDataSource {
  Future<List<HistoryEntity>> getAllHistory();
  Future<HistoryEntity?> getHistoryById(String id);
  Future<HistoryEntity?> getHistoryByKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  });

  /// Gets history by composite key directly (O(1) lookup).
  Future<HistoryEntity?> getHistoryByCompositeKey(String compositeKey);

  Future<void> saveHistory(HistoryEntity history);
  Future<void> deleteHistory(String id);
  Future<void> saveAllHistory(List<HistoryEntity> historyList);
  Future<void> clearAllHistory();

  /// Generates a composite key from surah/reciter/moshaf IDs.
  /// This key is deterministic and used for idempotent saves.
  String generateCompositeKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  });

  @Deprecated('Use generateCompositeKey instead for new entries')
  Future<String> generateHistoryId();

  Future<int> getHistoryCount();
}

@LazySingleton(as: HistoryLocalDataSource)
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(this._hive);

  static const String _historyBoxName = 'listening_history';
  static const String _historyCounterKey = '__history_counter__';
  static const int _maxHistorySize = 500; // Limit history entries

  final HiveInterface _hive;

  Future<Box> _getBox() async {
    if (_hive.isBoxOpen(_historyBoxName)) {
      return _hive.box(_historyBoxName);
    }
    return _hive.openBox(_historyBoxName);
  }

  @override
  Future<List<HistoryEntity>> getAllHistory() async {
    final box = await _getBox();
    final history = box.values.whereType<String>().map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return HistoryEntity.fromJson(map);
    }).toList();

    // Sort by played date (newest first)
    history.sort((a, b) => b.playedAt.compareTo(a.playedAt));

    return history;
  }

  @override
  Future<HistoryEntity?> getHistoryById(String id) async {
    final box = await _getBox();
    final jsonString = box.get(id);
    if (jsonString != null && jsonString is String) {
      return HistoryEntity.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<HistoryEntity?> getHistoryByKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async {
    // Since we store by ID, we must iterate to find by key
    // This efficiency is similar to the previous implementation (O(N))
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
    final box = await _getBox();
    await box.put(history.id, jsonEncode(history.toJson()));

    // Trim history if it exceeds max size
    // Note: This is an expensive operation as we load everything.
    // Hive keys are in order of insertion? No.
    // We already sorting in getAllHistory.
    // Optimization: only check if we added a new item.
    // For exactness, we reuse logic comparable to before but using Box methods.

    // Check total count (excluding counter key)
    final count = box.values.whereType<String>().length;
    if (count > _maxHistorySize) {
      final allHistory = await getAllHistory(); // Sorted newest first
      if (allHistory.length > _maxHistorySize) {
        final toRemove = allHistory.sublist(_maxHistorySize);
        final keysToRemove = toRemove.map((e) => e.id).toList();
        await box.deleteAll(keysToRemove);
      }
    }
  }

  @override
  Future<void> deleteHistory(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> saveAllHistory(List<HistoryEntity> historyList) async {
    final box = await _getBox();
    // Clear existing history items (strings) but keep counter?
    // Current implementation implies replacing everything.
    // But safely:
    // This method was used in SharedPreferences to save the whole list.
    // In Hive, we should probably clear and put all.
    // But let's check `clearAllHistory` logic in Data Source contract.
    // `saveAllHistory` is typically used for batch updates or reordering (if order mattered for storage).
    // Here we use it to save filtered lists (e.g. deleteOlderThan).

    // Strategy:
    // 1. Identify current keys (history items).
    // 2. Delete them.
    // 3. Put new items.

    final keysToDelete = box.keys
        .where((k) => k != _historyCounterKey)
        .toList();
    await box.deleteAll(keysToDelete);

    final Map<dynamic, String> entries = {
      for (var h in historyList) h.id: jsonEncode(h.toJson()),
    };
    await box.putAll(entries);
  }

  @override
  Future<void> clearAllHistory() async {
    final box = await _getBox();
    // We want to clear history items, maybe keep counter?
    // Previous impl removed `_historyKey` and `_historyCounterKey`.
    // So distinct box clear is fine.
    await box.clear();
  }

  @override
  Future<String> generateHistoryId() async {
    final box = await _getBox();
    final count = box.get(_historyCounterKey, defaultValue: 0) as int;
    final newCount = count + 1;
    await box.put(_historyCounterKey, newCount);
    return 'history_$newCount';
  }

  @override
  Future<int> getHistoryCount() async {
    final box = await _getBox();
    return box.values.whereType<String>().length;
  }

  @override
  String generateCompositeKey({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) {
    return '${surahId}_${reciterId}_$moshafId';
  }

  @override
  Future<HistoryEntity?> getHistoryByCompositeKey(String compositeKey) async {
    final box = await _getBox();
    final jsonString = box.get(compositeKey);
    if (jsonString != null && jsonString is String) {
      return HistoryEntity.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
