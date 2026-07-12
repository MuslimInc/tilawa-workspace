import 'package:injectable/injectable.dart';

import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';
import '../../domain/repositories/daily_guidance_repository.dart';
import '../datasources/daily_guidance_local_data_source.dart';
import '../datasources/daily_guidance_seed_data_source.dart';
import '../models/daily_guidance_item_model.dart';

@LazySingleton(as: DailyGuidanceRepository)
class DailyGuidanceRepositoryImpl implements DailyGuidanceRepository {
  final DailyGuidanceLocalDataSource _localDataSource;
  final DailyGuidanceSeedDataSource _seedDataSource;

  DailyGuidanceRepositoryImpl(
    this._localDataSource,
    this._seedDataSource,
  );

  @override
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
  }) async {
    final models = await _localDataSource.getItems();
    final items = models.map((m) => m.toEntity()).toList();
    return items.where((item) {
      if (item.status != ContentPublicationStatus.published) return false;
      if (!item.availableLocales.contains(locale)) return false;

      switch (contentMode) {
        case DailyGuidanceContentMode.quranOnly:
          if (item.type != DailyGuidanceItemType.quran) return false;
        case DailyGuidanceContentMode.hadithOnly:
          if (item.type != DailyGuidanceItemType.hadith) return false;
        case DailyGuidanceContentMode.mixed:
          break;
      }

      return true;
    }).toList();
  }

  @override
  Future<DailyGuidanceItem?> getItemById(String id) async {
    final models = await _localDataSource.getItems();
    try {
      final model = models.firstWhere((m) => m.id == id);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> refreshContent() async {
    // For MVP, we just load from the seed asset if the local box is empty.
    // In the future, this will sync from Firestore.
    final existing = await _localDataSource.getItems();
    if (existing.isNotEmpty) {
      return 0; // Already loaded
    }

    final seedItems = await _seedDataSource.loadSeedItems();
    if (seedItems.isNotEmpty) {
      await _localDataSource.saveItems(seedItems);
    }
    return seedItems.length;
  }
}
