import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reciter_model.dart';

abstract class RecitersLocalDataSource {
  Future<List<ReciterModel>> getReciters({String? language});
  Future<List<String>> getFavoriteReciterIds();
  Future<void> saveFavoriteReciterId(int id);
  Future<void> removeFavoriteReciterId(int id);
  Future<void> clearFavoriteReciterIds();
}

@LazySingleton(as: RecitersLocalDataSource)
class RecitersLocalDataSourceImpl implements RecitersLocalDataSource {
  RecitersLocalDataSourceImpl(this._prefs);
  final SharedPreferencesAsync _prefs;
  static const String _favoritesKey = 'favorite_reciter_ids';

  @override
  Future<List<ReciterModel>> getReciters({String? language}) async {
    try {
      // Default to Arabic if not specified
      final String lang = language ?? 'ar';

      // Determine filename based on language
      // API codes are 'ar' and 'eng', matching our saved files
      final fileName = 'assets/json/reciters_$lang.json';

      final String jsonString = await rootBundle.loadString(fileName);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final recitersList = data['reciters'] as List;

      return recitersList
          .map((json) => ReciterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load local reciters: $e');
    }
  }

  @override
  Future<List<String>> getFavoriteReciterIds() async {
    final List<String>? ids = await _prefs.getStringList(_favoritesKey);
    return ids ?? [];
  }

  @override
  Future<void> saveFavoriteReciterId(int id) async {
    final List<String> currentIds = await getFavoriteReciterIds();
    final idStr = id.toString();
    if (!currentIds.contains(idStr)) {
      final newIds = [...currentIds, idStr];
      await _prefs.setStringList(_favoritesKey, newIds);
    }
  }

  @override
  Future<void> removeFavoriteReciterId(int id) async {
    final List<String> currentIds = await getFavoriteReciterIds();
    final idStr = id.toString();
    if (currentIds.contains(idStr)) {
      final List<String> newIds = currentIds
          .where((element) => element != idStr)
          .toList();
      await _prefs.setStringList(_favoritesKey, newIds);
    }
  }

  @override
  Future<void> clearFavoriteReciterIds() async {
    await _prefs.remove(_favoritesKey);
  }
}
