import 'package:injectable/injectable.dart';

import '../entities/daily_guidance_item.dart';
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

  Future<DailyGuidanceItem?> call({required String localDate}) async {
    final existingRecord = await _recordRepository.getRecordForDate(localDate);
    if (existingRecord != null) {
      return _repository.getItemById(existingRecord.itemId);
    }
    return null;
  }
}
