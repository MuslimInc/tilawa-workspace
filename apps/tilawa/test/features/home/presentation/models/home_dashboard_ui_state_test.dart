import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/models/home_dashboard_ui_state.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

void main() {
  test('maps cold load states to full skeleton', () {
    expect(
      HomeDashboardUiState.from(const HomeDashboardInitial()).showFullSkeleton,
      isTrue,
    );
    expect(
      HomeDashboardUiState.from(const HomeDashboardLoading()).showFullSkeleton,
      isTrue,
    );
  });

  test('maps loaded dashboard to content without skeleton', () {
    final HomeDashboardUiState ui = HomeDashboardUiState.from(
      HomeDashboardLoaded(_dashboard),
    );

    expect(ui.showFullSkeleton, isFalse);
    expect(ui.showContent, isTrue);
    expect(ui.dashboard, _dashboard);
  });

  test('maps failure to hero error without full skeleton', () {
    final HomeDashboardUiState ui = HomeDashboardUiState.from(
      const HomeDashboardFailure(HomeDashboardFailureKind.offline),
    );

    expect(ui.showFullSkeleton, isFalse);
    expect(ui.showFailure, isTrue);
    expect(ui.failureIsOffline, isTrue);
  });
}

final HomeDashboard _dashboard = HomeDashboard(
  generatedAt: DateTime(2026, 6, 16, 18, 25),
  locationLabel: 'Cairo',
  nextPrayer: HomeNextPrayer(
    type: PrayerType.maghrib,
    time: DateTime(2026, 6, 16, 20, 0),
    timeUntil: const Duration(hours: 1),
  ),
  todayPrayers: [
    HomePrayerSlot(
      type: PrayerType.maghrib,
      time: DateTime(2026, 6, 16, 20, 0),
      isNext: true,
      hasPassed: false,
    ),
  ],
);
