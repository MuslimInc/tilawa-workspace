import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/hive_readiness.dart';

import '../../domain/entities/radio_station.dart';
import '../models/radio_station_mapper.dart';

abstract class RadioLocalDataSource {
  Future<List<RadioStation>> getCachedStations();
  Future<void> saveCachedStations(List<RadioStation> stations);
  Future<DateTime?> getCacheFetchedAt();

  Future<List<String>> getFavoriteIds();
  Future<void> saveFavoriteIds(List<String> ids);

  Future<List<RadioStation>> getRecentStations();
  Future<void> saveRecentStations(List<RadioStation> stations);
}

@LazySingleton(as: RadioLocalDataSource)
class RadioLocalDataSourceImpl implements RadioLocalDataSource {
  RadioLocalDataSourceImpl(this._hive, this._hiveReadiness, this._prefs);

  static const String _stationsBoxName = 'radio_stations';
  static const String _stationsKey = 'stations';
  static const String _fetchedAtKey = 'fetched_at';
  static const String _favoritesKey = 'radio_favorite_ids';
  static const String _recentBoxName = 'radio_recent';
  static const String _recentKey = 'recent';
  static const int maxRecentStations = 20;

  final HiveInterface _hive;
  final HiveReadiness _hiveReadiness;
  final SharedPreferencesAsync _prefs;

  Future<Box<dynamic>> _stationsBox() async {
    await _hiveReadiness.ensureReady();
    if (_hive.isBoxOpen(_stationsBoxName)) {
      return _hive.box(_stationsBoxName);
    }
    return _hive.openBox(_stationsBoxName);
  }

  Future<Box<dynamic>> _recentBox() async {
    await _hiveReadiness.ensureReady();
    if (_hive.isBoxOpen(_recentBoxName)) {
      return _hive.box(_recentBoxName);
    }
    return _hive.openBox(_recentBoxName);
  }

  @override
  Future<List<RadioStation>> getCachedStations() async {
    final box = await _stationsBox();
    final Object? raw = box.get(_stationsKey);
    if (raw is! String || raw.isEmpty) return const <RadioStation>[];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final Set<String> favoriteIds = (await getFavoriteIds()).toSet();
    return list.map((e) {
      final Map<String, dynamic> map = e as Map<String, dynamic>;
      return RadioStationMapper.fromCachedJson(
        map,
        isFavorite: favoriteIds.contains(map['id']?.toString()),
      );
    }).toList();
  }

  @override
  Future<void> saveCachedStations(List<RadioStation> stations) async {
    final box = await _stationsBox();
    final String encoded = jsonEncode(
      stations.map(RadioStationMapper.toCachedJson).toList(),
    );
    await box.put(_stationsKey, encoded);
    await box.put(_fetchedAtKey, DateTime.now().toIso8601String());
  }

  @override
  Future<DateTime?> getCacheFetchedAt() async {
    final box = await _stationsBox();
    final Object? raw = box.get(_fetchedAtKey);
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<List<String>> getFavoriteIds() async {
    return await _prefs.getStringList(_favoritesKey) ?? const <String>[];
  }

  @override
  Future<void> saveFavoriteIds(List<String> ids) async {
    await _prefs.setStringList(_favoritesKey, ids);
  }

  @override
  Future<List<RadioStation>> getRecentStations() async {
    final box = await _recentBox();
    final Object? raw = box.get(_recentKey);
    if (raw is! String || raw.isEmpty) return const <RadioStation>[];
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final Set<String> favoriteIds = (await getFavoriteIds()).toSet();
    return list.map((e) {
      final Map<String, dynamic> map = e as Map<String, dynamic>;
      return RadioStationMapper.fromCachedJson(
        map,
        isFavorite: favoriteIds.contains(map['id']?.toString()),
      );
    }).toList();
  }

  @override
  Future<void> saveRecentStations(List<RadioStation> stations) async {
    final box = await _recentBox();
    final List<RadioStation> capped = stations.take(maxRecentStations).toList();
    final String encoded = jsonEncode(
      capped.map(RadioStationMapper.toCachedJson).toList(),
    );
    await box.put(_recentKey, encoded);
  }
}
