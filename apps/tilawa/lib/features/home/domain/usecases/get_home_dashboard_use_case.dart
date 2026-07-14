import 'package:injectable/injectable.dart';

import '../entities/home_dashboard.dart';
import '../entities/home_dashboard_renderability.dart';
import '../repositories/home_dashboard_cache.dart';
import '../repositories/home_dashboard_repository.dart';

/// Returns the current Home dashboard snapshot.
@injectable
final class GetHomeDashboardUseCase {
  GetHomeDashboardUseCase(
    this._repository,
    this._cache,
  );

  final HomeDashboardRepository _repository;
  final HomeDashboardCache _cache;

  /// Last successful snapshot, when it is safe to render without skeleton.
  HomeDashboard? readCachedDashboard() {
    final HomeDashboard? cached = _cache.read();
    if (cached == null || !cached.isRenderable) {
      return null;
    }
    return cached;
  }

  Future<HomeDashboard> call({String? localeIdentifier}) async {
    final HomeDashboard dashboard = await _repository.getDashboard(
      localeIdentifier: localeIdentifier,
    );
    if (dashboard.isRenderable) {
      _cache.write(dashboard);
    }
    return dashboard;
  }

  Future<HomeDashboard> refreshLocation({String? localeIdentifier}) async {
    final HomeDashboard dashboard = await _repository.refreshLocation(
      localeIdentifier: localeIdentifier,
    );
    if (dashboard.isRenderable) {
      _cache.write(dashboard);
    }
    return dashboard;
  }
}
