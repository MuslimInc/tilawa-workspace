import '../entities/home_dashboard.dart';

/// In-memory snapshot cache for the Home dashboard composition.
abstract interface class HomeDashboardCache {
  HomeDashboard? read();

  void write(HomeDashboard dashboard);
}
