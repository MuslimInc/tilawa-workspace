import '../entities/home_dashboard.dart';
import '../repositories/home_dashboard_repository.dart';

/// Returns the current Home dashboard snapshot.
final class GetHomeDashboardUseCase {
  const GetHomeDashboardUseCase(this._repository);

  final HomeDashboardRepository _repository;

  Future<HomeDashboard> call() => _repository.getDashboard();
}
