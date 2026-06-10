import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/tasbeeh_dhikr.dart';

abstract class TasbeehRepository {
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr();
  ResultFuture<TasbeehDhikr> saveCustomDhikr({
    required String text,
    required int targetCount,
  });
  ResultFuture<TasbeehDhikr> incrementCount(String dhikrId);
  ResultFuture<TasbeehDhikr> resetCount(String dhikrId);
  ResultFuture<TasbeehDhikr> setTargetCount({
    required String dhikrId,
    required int targetCount,
  });
  ResultVoid deleteDhikr(String dhikrId);
  ResultVoid deleteAllDhikr();
  ResultFuture<TasbeehDhikr> setReminder({
    required String dhikrId,
    required bool enabled,
    int? hour,
    int? minute,
  });
}
