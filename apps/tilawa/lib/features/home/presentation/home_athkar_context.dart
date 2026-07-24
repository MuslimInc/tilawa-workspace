import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

/// Builds prayer anchors for Athkar context from a Home dashboard snapshot.
AthkarPrayerAnchors? athkarPrayerAnchorsFromDashboard(
  HomeDashboard? dashboard,
) {
  final boundaries = dashboard?.prayerBoundaries;
  if (boundaries == null) {
    return null;
  }

  DateTime? asr;
  for (final HomePrayerSlot slot in dashboard?.todayPrayers ?? const []) {
    if (slot.type == PrayerType.asr) {
      asr = slot.time;
      break;
    }
  }

  return AthkarPrayerAnchors(
    fajr: boundaries.fajr,
    asr: asr,
    maghrib: boundaries.maghrib,
    isha: boundaries.isha,
  );
}

/// Resolves the Home Athkar recommendation from compact progress + prayer data.
AthkarContextRecommendation resolveHomeAthkarRecommendation({
  required HomeAthkarCompactState athkarState,
  required DateTime now,
  HomeDashboard? dashboard,
}) {
  return resolveAthkarContextRecommendation(
    now: now,
    prayerAnchors: athkarPrayerAnchorsFromDashboard(dashboard),
    completions: homeAthkarCompletions(athkarState),
  );
}
