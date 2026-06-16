import '../../domain/entities/khatma_plan.dart';
import '../../domain/repositories/khatma_plan_repository.dart';
import '../datasources/khatma_plan_local_datasource.dart';

final class KhatmaPlanRepositoryImpl implements KhatmaPlanRepository {
  const KhatmaPlanRepositoryImpl(this._localDataSource);

  final KhatmaPlanLocalDataSource _localDataSource;

  @override
  Future<KhatmaPlan?> getActivePlan() => _localDataSource.getActivePlan();

  @override
  Future<void> saveActivePlan(KhatmaPlan plan) {
    return _localDataSource.saveActivePlan(plan);
  }

  @override
  Future<void> clearActivePlan() => _localDataSource.clearActivePlan();
}
