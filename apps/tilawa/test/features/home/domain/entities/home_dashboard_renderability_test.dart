import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard_renderability.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

void main() {
  test('dashboard with prayer location is renderable', () {
    final HomeDashboard dashboard = HomeDashboard(
      generatedAt: _generatedAt,
      locationLabel: 'Cairo',
    );

    expect(dashboard.isRenderable, isTrue);
  });

  test('empty dashboard is not renderable', () {
    final HomeDashboard dashboard = HomeDashboard(generatedAt: _generatedAt);

    expect(dashboard.isRenderable, isFalse);
  });

  test('dashboard with next prayer only is renderable', () {
    final HomeDashboard dashboard = HomeDashboard(
      generatedAt: _generatedAt,
      nextPrayer: HomeNextPrayer(
        type: PrayerType.maghrib,
        time: DateTime(2026, 6, 16, 20, 0),
        timeUntil: const Duration(hours: 1),
      ),
    );

    expect(dashboard.isRenderable, isTrue);
  });
}

final DateTime _generatedAt = DateTime(2026, 6, 16, 18, 25);
