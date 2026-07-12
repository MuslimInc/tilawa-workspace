import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../models/daily_delivery_record_model.dart';
import '../models/daily_guidance_item_model.dart';

@lazySingleton
class DailyGuidanceLocalDataSource {
  static const String itemsBoxName = 'daily_guidance_items';
  static const String recordsBoxName = 'daily_guidance_delivery_records';

  final Box<String> _itemsBox;
  final Box<String> _recordsBox;

  DailyGuidanceLocalDataSource(
    @Named(itemsBoxName) this._itemsBox,
    @Named(recordsBoxName) this._recordsBox,
  );

  // --- Items ---

  Future<List<DailyGuidanceItemModel>> getItems() async {
    return _itemsBox.values.map((jsonStr) {
      // We map via string JSON to avoid writing custom Hive adapters for MVP
      // (KISS principle applied)
      return DailyGuidanceItemModel.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> saveItems(List<DailyGuidanceItemModel> items) async {
    final map = {for (final item in items) item.id: jsonEncode(item.toJson())};
    await _itemsBox.putAll(map);
  }

  // --- Delivery Records ---

  Future<DailyDeliveryRecordModel?> getRecord(String localDate) async {
    final jsonStr = _recordsBox.get(localDate);
    if (jsonStr == null) return null;

    return DailyDeliveryRecordModel.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  Future<void> saveRecord(DailyDeliveryRecordModel record) async {
    await _recordsBox.put(record.localDate, jsonEncode(record.toJson()));
  }

  Future<List<DailyDeliveryRecordModel>> getAllRecords() async {
    return _recordsBox.values.map((jsonStr) {
      return DailyDeliveryRecordModel.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> deleteRecords(List<String> localDates) async {
    await _recordsBox.deleteAll(localDates);
  }
}
