import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/constants/tasbeeh_constants.dart';
import '../models/tasbeeh_dhikr_model.dart';

abstract class TasbeehLocalDataSource {
  Future<List<TasbeehDhikrModel>> getAllDhikr();
  Future<TasbeehDhikrModel?> getDhikrById(String id);
  Future<void> saveDhikr(TasbeehDhikrModel model);
  Future<void> deleteDhikr(String id);
}

@LazySingleton(as: TasbeehLocalDataSource)
class TasbeehLocalDataSourceImpl implements TasbeehLocalDataSource {
  TasbeehLocalDataSourceImpl(this._hive);

  final HiveInterface _hive;

  Future<Box> _getBox() async {
    if (_hive.isBoxOpen(TasbeehConstants.storageBoxName)) {
      return _hive.box(TasbeehConstants.storageBoxName);
    }
    return _hive.openBox(TasbeehConstants.storageBoxName);
  }

  @override
  Future<List<TasbeehDhikrModel>> getAllDhikr() async {
    final box = await _getBox();
    final items = box.values.whereType<String>().map((raw) {
      return TasbeehDhikrModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }).toList();

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<TasbeehDhikrModel?> getDhikrById(String id) async {
    final box = await _getBox();
    final raw = box.get(id);
    if (raw is! String) {
      return null;
    }

    return TasbeehDhikrModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveDhikr(TasbeehDhikrModel model) async {
    final box = await _getBox();
    await box.put(model.id, jsonEncode(model.toJson()));
  }

  @override
  Future<void> deleteDhikr(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
