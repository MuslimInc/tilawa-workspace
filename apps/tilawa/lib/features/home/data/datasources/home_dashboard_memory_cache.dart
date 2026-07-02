import 'package:flutter/foundation.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';

/// Process-wide memory cache for the last successful Home dashboard snapshot.
final class HomeDashboardMemoryCache {
  HomeDashboardMemoryCache();

  static final HomeDashboardMemoryCache shared = HomeDashboardMemoryCache();

  HomeDashboard? _dashboard;

  HomeDashboard? read() => _dashboard;

  void write(HomeDashboard dashboard) {
    _dashboard = dashboard;
  }

  @visibleForTesting
  void clear() {
    _dashboard = null;
  }
}
