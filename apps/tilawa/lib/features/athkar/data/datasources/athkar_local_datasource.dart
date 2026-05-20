import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../models/athkar_category_model.dart';
import '../models/athkar_item_model.dart';

abstract class AthkarLocalDataSource {
  Future<List<AthkarCategoryModel>> getCategories();
  Future<List<AthkarItemModel>> getAthkarByCategory(int categoryId);
}

@LazySingleton(as: AthkarLocalDataSource)
class AthkarLocalDataSourceImpl implements AthkarLocalDataSource {
  AthkarLocalDataSourceImpl({required this._assetBundle});

  final AssetBundle _assetBundle;
  static const String _assetPath = 'assets/data/athkar.json';

  @override
  Future<List<AthkarCategoryModel>> getCategories() async {
    final String response = await _assetBundle.loadString(_assetPath);
    final data = await json.decode(response) as Map<String, dynamic>;
    final categories = data['categories'] as List;
    return categories
        .map((e) => AthkarCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AthkarItemModel>> getAthkarByCategory(int categoryId) async {
    final String response = await _assetBundle.loadString(_assetPath);
    final data = await json.decode(response) as Map<String, dynamic>;
    final athkar = data['athkar'] as List;
    return athkar
        .map((e) => AthkarItemModel.fromJson(e as Map<String, dynamic>))
        .where((element) => element.categoryId == categoryId)
        .toList();
  }
}
