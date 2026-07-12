import 'package:injectable/injectable.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';
import '../../domain/entities/daily_guidance_locale.dart';
import '../../domain/repositories/daily_guidance_repository.dart';
import '../datasources/daily_guidance_local_data_source.dart';
import '../datasources/daily_guidance_seed_data_source.dart';
import '../mappers/daily_guidance_content_validator.dart';
import '../models/daily_guidance_item_model.dart';

@LazySingleton(as: DailyGuidanceRepository)
class DailyGuidanceRepositoryImpl implements DailyGuidanceRepository {
  final DailyGuidanceLocalDataSource _localDataSource;
  final DailyGuidanceSeedDataSource _seedDataSource;
  final DailyGuidanceContentValidator _validator =
      const DailyGuidanceContentValidator();

  DailyGuidanceRepositoryImpl(
    this._localDataSource,
    this._seedDataSource,
  );

  @override
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
    required DailyGuidanceCapability capability,
  }) async {
    final normalizedLocale = DailyGuidanceLocale.parse(locale)?.name;
    if (normalizedLocale == null) return [];
    final models = await _localDataSource.getItems();
    final items = models
        .map(
          (model) => _validator.validate(
            model: model,
            locale: normalizedLocale,
            capability: capability,
          ),
        )
        .whereType<DailyGuidanceItem>()
        .toList();
    return items.where((item) {
      if (item.status != ContentPublicationStatus.published) return false;
      if (!item.availableLocales.contains(normalizedLocale)) return false;

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
  Future<DailyGuidanceItem?> getItemById({
    required String id,
    required String locale,
    required DailyGuidanceCapability capability,
  }) async {
    final normalizedLocale = DailyGuidanceLocale.parse(locale)?.name;
    if (normalizedLocale == null) return null;
    final models = await _localDataSource.getItems();
    final matchingModels = models.where((model) => model.id == id);
    if (matchingModels.isEmpty) return null;
    return _validator.validate(
      model: matchingModels.first,
      locale: normalizedLocale,
      capability: capability,
    );
  }

  @override
  Future<int> refreshContent() async {
    List<DailyGuidanceItemModel> existing;
    try {
      existing = await _localDataSource.getItems();
    } on DailyGuidanceParsingException catch (error, stackTrace) {
      logger.w(
        'Discarding corrupt Daily Guidance content cache',
        error: error,
        stackTrace: stackTrace,
      );
      await _localDataSource.clearItems();
      existing = [];
    }
    final needsProvenanceMigration = existing.any(
      (model) =>
          model.shortExplanationSourceIds == null ||
          (model.translations?.isNotEmpty ?? false) &&
              model.translationSourceIds == null,
    );
    if (existing.isNotEmpty && !needsProvenanceMigration) return 0;

    final seedItems = await _seedDataSource.loadSeedItems();
    if (seedItems.isNotEmpty) {
      await _localDataSource.saveItems(seedItems);
    }
    return seedItems.length;
  }
}
