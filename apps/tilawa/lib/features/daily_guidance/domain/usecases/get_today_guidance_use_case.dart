import 'package:injectable/injectable.dart';

import '../entities/daily_guidance_item.dart';
import '../entities/daily_guidance_enums.dart';
import '../repositories/daily_delivery_record_repository.dart';
import '../repositories/daily_guidance_repository.dart';

/// Returns the committed item for today without attempting to select a new one.
@injectable
class GetTodayGuidanceUseCase {
  final DailyGuidanceRepository _repository;
  final DailyDeliveryRecordRepository _recordRepository;

  const GetTodayGuidanceUseCase(
    this._repository,
    this._recordRepository,
  );

  Future<DailyGuidanceItem?> call({
    required String localDate,
    required String locale,
    required DailyGuidanceCapability capability,
  }) async {
    final existingRecord = await _recordRepository.getRecordForDate(localDate);
    if (existingRecord != null) {
      return _repository.getItemById(
        id: existingRecord.itemId,
        locale: locale,
        capability: capability,
      );
    }
    return null;
  }
}
