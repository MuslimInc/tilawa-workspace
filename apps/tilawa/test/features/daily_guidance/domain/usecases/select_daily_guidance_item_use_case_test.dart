import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/daily_guidance/domain/entities/daily_delivery_record.dart';
import 'package:tilawa/features/daily_guidance/domain/entities/daily_guidance_enums.dart';
import 'package:tilawa/features/daily_guidance/domain/entities/daily_guidance_item.dart';
import 'package:tilawa/features/daily_guidance/domain/entities/daily_guidance_preferences.dart';
import 'package:tilawa/features/daily_guidance/domain/repositories/daily_delivery_record_repository.dart';
import 'package:tilawa/features/daily_guidance/domain/repositories/daily_guidance_repository.dart';
import 'package:tilawa/features/daily_guidance/domain/usecases/select_daily_guidance_item_use_case.dart';

void main() {
  test(
    'new daily selection requests notification-safe localized content',
    () async {
      final guidanceRepository = _RecordingGuidanceRepository();
      final useCase = SelectDailyGuidanceItemUseCase(
        guidanceRepository,
        _RecordRepository(),
      );

      await useCase(
        localDate: '2026-07-12',
        preferences: DailyGuidancePreferences(
          updatedAt: DateTime.utc(2026, 7, 12),
        ),
        locale: 'ar',
      );

      check(guidanceRepository.eligibleLocale).equals('ar');
      check(
        guidanceRepository.eligibleCapability,
      ).equals(DailyGuidanceCapability.notification);
    },
  );

  test('committed daily item is revalidated for display and locale', () async {
    final guidanceRepository = _RecordingGuidanceRepository();
    final useCase = SelectDailyGuidanceItemUseCase(
      guidanceRepository,
      _RecordRepository(
        record: const DailyDeliveryRecord(
          localDate: '2026-07-12',
          itemId: 'hadith_bukhari_6412',
          itemRevision: 1,
          deliveryStatus: DeliveryStatus.selected,
        ),
      ),
    );

    await useCase(
      localDate: '2026-07-12',
      preferences: DailyGuidancePreferences(
        updatedAt: DateTime.utc(2026, 7, 12),
      ),
      locale: 'en',
    );

    check(guidanceRepository.itemId).equals('hadith_bukhari_6412');
    check(guidanceRepository.itemLocale).equals('en');
    check(
      guidanceRepository.itemCapability,
    ).equals(DailyGuidanceCapability.display);
  });
}

class _RecordingGuidanceRepository implements DailyGuidanceRepository {
  String? eligibleLocale;
  DailyGuidanceCapability? eligibleCapability;
  String? itemId;
  String? itemLocale;
  DailyGuidanceCapability? itemCapability;

  @override
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
    required DailyGuidanceCapability capability,
  }) async {
    eligibleLocale = locale;
    eligibleCapability = capability;
    return [];
  }

  @override
  Future<DailyGuidanceItem?> getItemById({
    required String id,
    required String locale,
    required DailyGuidanceCapability capability,
  }) async {
    itemId = id;
    itemLocale = locale;
    itemCapability = capability;
    return null;
  }

  @override
  Future<int> refreshContent() async => 0;
}

class _RecordRepository implements DailyDeliveryRecordRepository {
  _RecordRepository({this.record});

  final DailyDeliveryRecord? record;

  @override
  Future<DailyDeliveryRecord?> getRecordForDate(String localDate) async =>
      record;

  @override
  Future<Set<String>> getRecentlyDeliveredItemIds({required int days}) async =>
      {};

  @override
  Future<List<DailyDeliveryRecord>> getRecentRecords({int limit = 30}) async =>
      [];

  @override
  Future<void> pruneOldRecords({required int keepDays}) async {}

  @override
  Future<void> saveRecord(DailyDeliveryRecord record) async {}
}
