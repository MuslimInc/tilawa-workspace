// JSON cast errors must become typed content failures at this trust boundary.
// ignore_for_file: avoid_catching_errors

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
    } on FormatException catch (error) {
      throw DailyGuidanceParsingException(_seedAssetPath, error);
    } on TypeError catch (error) {
      throw DailyGuidanceParsingException(_seedAssetPath, error);
    } on StateError catch (error) {
      throw DailyGuidanceParsingException(_seedAssetPath, error);
    }
  }
}

/// Signals that untrusted guidance JSON could not be parsed atomically.
class DailyGuidanceParsingException implements Exception {
  const DailyGuidanceParsingException(this.source, this.cause);

  final String source;
  final Object cause;

  @override
  String toString() => 'Invalid Daily Guidance content in $source: $cause';
}
