import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Host-layer analytics for the Home Learn Quran featured card.
///
/// The card view event is a render/impression proxy (logged once per widget
/// lifecycle while the feature flag is enabled) — not true viewport visibility.
void _logHomeLearnQuranEvent(String name) {
  if (!getIt.isRegistered<AnalyticsService>()) return;
  getIt<AnalyticsService>().logEvent(name);
}

void logHomeLearnQuranCardViewed() =>
    _logHomeLearnQuranEvent(AnalyticsEvents.homeLearnQuranCardViewed);

void logHomeLearnQuranCardTapped() =>
    _logHomeLearnQuranEvent(AnalyticsEvents.homeLearnQuranCardTapped);
