import 'dart:math';
import 'package:injectable/injectable.dart';

import '../entities/daily_delivery_record.dart';
import '../entities/daily_guidance_enums.dart';
import '../entities/daily_guidance_item.dart';
import '../entities/daily_guidance_preferences.dart';
import '../repositories/daily_delivery_record_repository.dart';
import '../repositories/daily_guidance_repository.dart';

/// Selects (or retrieves the already-committed) daily guidance item for
/// the given local date.
///
/// Selection contract:
/// 1. If a delivery record exists for today -> return the committed item.
/// 2. Otherwise, select from eligible candidates using the policy:
///    - Filter by content mode, locale.
///    - Exclude recently delivered IDs (90-day window).
///    - Apply deterministic selection based on date seed.
///    - Persist the selection as committed.
/// 3. Returns null if no eligible content exists.
@injectable
class SelectDailyGuidanceItemUseCase {
  final DailyGuidanceRepository _repository;
  final DailyDeliveryRecordRepository _recordRepository;

  const SelectDailyGuidanceItemUseCase(
    this._repository,
    this._recordRepository,
  );

  Future<DailyGuidanceItem?> call({
    required String localDate,
    required DailyGuidancePreferences preferences,
    required String locale,
  }) async {
    // 0. Ensure seed data is loaded into local storage if empty
    await _repository.refreshContent();

    // 1. Check if already committed for today
    final existingRecord = await _recordRepository.getRecordForDate(localDate);
    if (existingRecord != null) {
      return _repository.getItemById(
        id: existingRecord.itemId,
        locale: locale,
        capability: DailyGuidanceCapability.display,
      );
    }

    // 2. Load candidates
    var candidates = await _repository.getEligibleItems(
      contentMode: preferences.contentMode,
      locale: locale,
      capability: DailyGuidanceCapability.notification,
    );

    if (candidates.isEmpty) {
      // Fallback to mixed mode if user requested mode is empty
      if (preferences.contentMode != DailyGuidanceContentMode.mixed) {
        candidates = await _repository.getEligibleItems(
          contentMode: DailyGuidanceContentMode.mixed,
          locale: locale,
          capability: DailyGuidanceCapability.notification,
        );
      }
      if (candidates.isEmpty) {
        return null;
      }
    }

    // 3. Filter recently delivered
    final recentIds = await _recordRepository.getRecentlyDeliveredItemIds(
      days: 90,
    );
    var eligibleCandidates = candidates
        .where((c) => !recentIds.contains(c.id))
        .toList();

    // If we exhausted the corpus, reuse all candidates
    if (eligibleCandidates.isEmpty) {
      eligibleCandidates = candidates;
    }

    // 4. Deterministic selection
    // Sort to ensure stable order across devices
    eligibleCandidates.sort((a, b) => a.id.compareTo(b.id));

    // Seed based on the date string
    final seed = localDate.hashCode;
    final random = Random(seed);
    final selectedIndex = random.nextInt(eligibleCandidates.length);
    final selectedItem = eligibleCandidates[selectedIndex];

    // 5. Commit record
    final record = DailyDeliveryRecord(
      localDate: localDate,
      itemId: selectedItem.id,
      itemRevision: selectedItem.revision,
      deliveryStatus: DeliveryStatus.selected,
      selectionReason: 'normal',
    );
    await _recordRepository.saveRecord(record);

    return selectedItem;
  }
}
