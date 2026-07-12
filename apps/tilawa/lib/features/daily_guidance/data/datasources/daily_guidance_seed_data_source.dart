import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../models/daily_guidance_item_model.dart';

@lazySingleton
class DailyGuidanceSeedDataSource {
  static const String _seedAssetPath = 'assets/daily_guidance_seed.json';

  Future<List<DailyGuidanceItemModel>> loadSeedItems() async {
    try {
      final String jsonString = await rootBundle.loadString(_seedAssetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map(
            (json) =>
                DailyGuidanceItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on Exception catch (_) {
      // In a real app we'd log this properly. If the seed is missing or malformed,
      // we return empty and handle gracefully.
      return [];
    }
  }
}
