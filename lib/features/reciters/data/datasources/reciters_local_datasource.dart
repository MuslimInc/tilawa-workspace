import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../models/reciter_model.dart';

abstract class RecitersLocalDataSource {
  Future<List<ReciterModel>> getReciters({String? language});
}

@LazySingleton(as: RecitersLocalDataSource)
class RecitersLocalDataSourceImpl implements RecitersLocalDataSource {
  @override
  Future<List<ReciterModel>> getReciters({String? language}) async {
    try {
      // Default to Arabic if not specified
      final String lang = language ?? 'ar';

      // Determine filename based on language
      // API codes are 'ar' and 'eng', matching our saved files
      final fileName = 'assets/json/reciters_$lang.json';

      final String jsonString = await rootBundle.loadString(fileName);
      final Map<String, dynamic> data = json.decode(jsonString);
      final recitersList = data['reciters'] as List;

      return recitersList
          .map((json) => ReciterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load local reciters: $e');
    }
  }
}
