import 'home_dashboard.dart';

extension HomeDashboardRenderability on HomeDashboard {
  /// Whether the snapshot is safe to show instead of the full Home skeleton.
  bool get isRenderable =>
      hasPrayerLocation || nextPrayer != null || todayPrayers.isNotEmpty;
}
