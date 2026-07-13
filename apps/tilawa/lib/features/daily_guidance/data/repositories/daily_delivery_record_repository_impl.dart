import 'package:injectable/injectable.dart';

import '../../domain/entities/daily_delivery_record.dart';
import '../../domain/repositories/daily_delivery_record_repository.dart';
import '../datasources/daily_guidance_local_data_source.dart';
import '../models/daily_delivery_record_model.dart';

@LazySingleton(as: DailyDeliveryRecordRepository)
class DailyDeliveryRecordRepositoryImpl
    implements DailyDeliveryRecordRepository {
  final DailyGuidanceLocalDataSource _localDataSource;

  DailyDeliveryRecordRepositoryImpl(this._localDataSource);

  @override
  Future<DailyDeliveryRecord?> getRecordForDate(String localDate) async {
    final model = await _localDataSource.getRecord(localDate);
    return model?.toEntity();
  }

  @override
  Future<void> saveRecord(DailyDeliveryRecord record) async {
    final model = record.toModel();
    await _localDataSource.saveRecord(model);
  }

  @override
  Future<Set<String>> getRecentlyDeliveredItemIds({required int days}) async {
    final records = await _localDataSource.getAllRecords();
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final recentRecords = records.where((r) {
      try {
        final recordDate = DateTime.parse(r.localDate);
        return recordDate.isAfter(cutoff);
      } on FormatException {
        return false;
      }
    });

    return recentRecords.map((r) => r.itemId).toSet();
  }

  @override
  Future<List<DailyDeliveryRecord>> getRecentRecords({int limit = 30}) async {
    final records = await _localDataSource.getAllRecords();
    records.sort((a, b) => b.localDate.compareTo(a.localDate)); // Descending
    return records.take(limit).map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> pruneOldRecords({required int keepDays}) async {
    final records = await _localDataSource.getAllRecords();
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));

    final toDelete = records
        .where((r) {
          try {
            final recordDate = DateTime.parse(r.localDate);
            return recordDate.isBefore(cutoff);
          } on FormatException {
            return true; // Prune invalid dates
          }
        })
        .map((r) => r.localDate)
        .toList();

    if (toDelete.isNotEmpty) {
      await _localDataSource.deleteRecords(toDelete);
    }
  }
}
