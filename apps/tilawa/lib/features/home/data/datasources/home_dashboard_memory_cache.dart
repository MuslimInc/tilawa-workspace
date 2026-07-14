import 'package:flutter/foundation.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_dashboard_cache.dart';

final class HomeDashboardMemoryCache implements HomeDashboardCache {
  HomeDashboardMemoryCache();

  static final HomeDashboardMemoryCache shared = HomeDashboardMemoryCache();

  HomeDashboard? _dashboard;

  @override
  HomeDashboard? read() => _dashboard;

  @override
  void write(HomeDashboard dashboard) {
    _dashboard = dashboard;
  }

  @visibleForTesting
  void clear() {
    _dashboard = null;
  }
}
