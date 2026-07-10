import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Host-layer analytics for the Home Learn Quran card slot.
void logHomeLearnQuranCardAction({
  required String action,
  required String status,
  String? bookingId,
}) {
  if (!getIt.isRegistered<AnalyticsService>()) return;
  getIt<AnalyticsService>().logEvent(
    'home_learn_quran_card_action',
    parameters: {
      'action': action,
      'status': status,
      'booking_id': ?bookingId,
    },
  );
}
