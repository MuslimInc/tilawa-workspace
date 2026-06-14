import '../entities/home_dashboard.dart';

/// Loads the composed Home dashboard from existing Tilawa domain features.
abstract interface class HomeDashboardRepository {
  Future<HomeDashboard> getDashboard();
}
