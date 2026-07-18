import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_engagement.dart';
import '../../domain/entities/reel_reaction.dart';

abstract class ReelsLocalDataSource {
  Future<List<Reel>> getSavedReels();
  Future<void> saveReel(Reel reel);
  Future<void> removeSavedReel(int reelId);
  Future<bool> isSaved(int reelId);
  Future<Set<int>> getSavedIds();

  Future<Map<int, ReelEngagement>> getEngagementMap();
  Future<void> saveEngagement(int reelId, ReelEngagement engagement);

  Future<Map<int, ReelReaction>> getReactions();
  Future<void> setReaction(int reelId, ReelReaction? reaction);
}

@LazySingleton(as: ReelsLocalDataSource)
class ReelsLocalDataSourceImpl implements ReelsLocalDataSource {
  ReelsLocalDataSourceImpl(this._prefs);

  static const String _savedKey = 'reels_saved';
  static const String _engagementKey = 'reels_engagement';
  static const String _reactionsKey = 'reels_reactions';

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<Reel>> getSavedReels() async {
    final List<String> raw = await _prefs.getStringList(_savedKey) ?? [];
    return raw
        .map((s) => Reel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .map((r) => r.copyWith(isSaved: true))
        .toList();
  }

  @override
  Future<void> saveReel(Reel reel) async {
    final list = await getSavedReels();
    final updated = reel.copyWith(isSaved: true);
    final index = list.indexWhere((r) => r.id == reel.id);
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.insert(0, updated);
    }
    await _writeSaved(list);
  }

  @override
  Future<void> removeSavedReel(int reelId) async {
    final list = await getSavedReels();
    list.removeWhere((r) => r.id == reelId);
    await _writeSaved(list);
  }

  @override
  Future<bool> isSaved(int reelId) async {
    final ids = await getSavedIds();
    return ids.contains(reelId);
  }

  @override
  Future<Set<int>> getSavedIds() async {
    final list = await getSavedReels();
    return list.map((r) => r.id).toSet();
  }

  Future<void> _writeSaved(List<Reel> reels) async {
    await _prefs.setStringList(
      _savedKey,
      reels.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  @override
  Future<Map<int, ReelEngagement>> getEngagementMap() async {
    final String? raw = await _prefs.getString(_engagementKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries)
        int.parse(e.key): ReelEngagement.fromJson(
          e.value as Map<String, dynamic>,
        ),
    };
  }

  @override
  Future<void> saveEngagement(int reelId, ReelEngagement engagement) async {
    final map = await getEngagementMap();
    map[reelId] = engagement;
    await _prefs.setString(
      _engagementKey,
      jsonEncode({
        for (final e in map.entries) e.key.toString(): e.value.toJson(),
      }),
    );
  }

  @override
  Future<Map<int, ReelReaction>> getReactions() async {
    final String? raw = await _prefs.getString(_reactionsKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final result = <int, ReelReaction>{};
    for (final e in map.entries) {
      final reaction = ReelReaction.values
          .where((r) => r.name == e.value)
          .firstOrNull;
      if (reaction != null) {
        result[int.parse(e.key)] = reaction;
      }
    }
    return result;
  }

  @override
  Future<void> setReaction(int reelId, ReelReaction? reaction) async {
    final map = await getReactions();
    if (reaction == null) {
      map.remove(reelId);
    } else {
      map[reelId] = reaction;
    }
    await _prefs.setString(
      _reactionsKey,
      jsonEncode({for (final e in map.entries) e.key.toString(): e.value.name}),
    );
  }
}
