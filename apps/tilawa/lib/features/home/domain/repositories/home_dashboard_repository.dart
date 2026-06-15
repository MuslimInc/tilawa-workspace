import '../entities/home_dashboard.dart';

/// Loads the composed Home dashboard from existing Tilawa domain features.
abstract interface class HomeDashboardRepository {
  Future<HomeDashboard> getDashboard({String? localeIdentifier});

  /// Requests a fresh GPS fix, persists it, and returns an updated dashboard.
  Future<HomeDashboard> refreshLocation({String? localeIdentifier});
}
