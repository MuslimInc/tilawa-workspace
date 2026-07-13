// JSON cast errors must become typed content failures at this trust boundary.
// ignore_for_file: avoid_catching_errors

import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/hive_readiness.dart';
import '../models/daily_delivery_record_model.dart';
import '../models/daily_guidance_item_model.dart';
import 'daily_guidance_seed_data_source.dart';

@lazySingleton
class DailyGuidanceLocalDataSource {
  static const String itemsBoxName = 'daily_guidance_items';
  static const String recordsBoxName = 'daily_guidance_delivery_records';

  final HiveInterface _hive;
  final HiveReadiness _hiveReadiness;

  DailyGuidanceLocalDataSource(this._hive, this._hiveReadiness);

  Future<Box<String>> _getItemsBox() async {
    await _hiveReadiness.ensureReady();
    if (_hive.isBoxOpen(itemsBoxName)) {
      return _hive.box<String>(itemsBoxName);
    }
    return _hive.openBox<String>(itemsBoxName);
  }

  Future<Box<String>> _getRecordsBox() async {
    await _hiveReadiness.ensureReady();
    if (_hive.isBoxOpen(recordsBoxName)) {
      return _hive.box<String>(recordsBoxName);
    }
    return _hive.openBox<String>(recordsBoxName);
  }

  // --- Items ---

  Future<List<DailyGuidanceItemModel>> getItems() async {
    final box = await _getItemsBox();
    return box.values.map(_parseItem).toList();
  }

  DailyGuidanceItemModel _parseItem(String jsonString) {
    try {
      return DailyGuidanceItemModel.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } on FormatException catch (error) {
      throw DailyGuidanceParsingException(itemsBoxName, error);
    } on TypeError catch (error) {
      throw DailyGuidanceParsingException(itemsBoxName, error);
    } on StateError catch (error) {
      throw DailyGuidanceParsingException(itemsBoxName, error);
    }
  }

  Future<void> saveItems(List<DailyGuidanceItemModel> items) async {
    final box = await _getItemsBox();
    final map = {for (final item in items) item.id: jsonEncode(item.toJson())};
    await box.putAll(map);
  }

  Future<void> clearItems() async {
    final box = await _getItemsBox();
    await box.clear();
  }

  // --- Delivery Records ---

  Future<DailyDeliveryRecordModel?> getRecord(String localDate) async {
    final box = await _getRecordsBox();
    final jsonStr = box.get(localDate);
    if (jsonStr == null) return null;

    return DailyDeliveryRecordModel.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  Future<void> saveRecord(DailyDeliveryRecordModel record) async {
    final box = await _getRecordsBox();
    await box.put(record.localDate, jsonEncode(record.toJson()));
  }

  Future<List<DailyDeliveryRecordModel>> getAllRecords() async {
    final box = await _getRecordsBox();
    return box.values.map((jsonStr) {
      return DailyDeliveryRecordModel.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> deleteRecords(List<String> localDates) async {
    final box = await _getRecordsBox();
    await box.deleteAll(localDates);
  }
}
