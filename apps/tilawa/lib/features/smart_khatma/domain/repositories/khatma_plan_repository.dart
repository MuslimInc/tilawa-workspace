import '../entities/khatma_plan.dart';

abstract interface class KhatmaPlanRepository {
  Future<KhatmaPlan?> getActivePlan();

  Future<void> saveActivePlan(KhatmaPlan plan);

  Future<void> clearActivePlan();
}
