import 'package:flutter/foundation.dart';

/// Scheduling experiment analytics — wired by the host app.
@immutable
class QuranSessionsSchedulingAnalyticsCallbacks {
  const QuranSessionsSchedulingAnalyticsCallbacks({
    this.onWeekViewOpened,
    this.onFridayReviewBannerShown,
    this.onFridayReviewBannerTapped,
    this.onFridayReviewBannerDismissed,
    this.onWeeklyTemplateOpened,
    this.onWeeklyTemplateSaved,
    this.onBookingLostDueToNoAvailability,
  });

  /// [parameters] should include scheduling_mode, policy_version, market_code.
  final void Function(Map<String, Object> parameters)? onWeekViewOpened;

  final void Function(Map<String, Object> parameters)?
  onFridayReviewBannerShown;

  final void Function(Map<String, Object> parameters)?
  onFridayReviewBannerTapped;

  final void Function(Map<String, Object> parameters)?
  onFridayReviewBannerDismissed;

  final void Function(Map<String, Object> parameters)? onWeeklyTemplateOpened;

  /// [parameters] should include scheduling_mode, policy_version, days_open,
  /// duration_changed, and market_code when available.
  final void Function(Map<String, Object> parameters)? onWeeklyTemplateSaved;

  /// [parameters] should include teacher_id, requested_from, requested_to,
  /// and market_code when available.
  final void Function(Map<String, Object> parameters)?
  onBookingLostDueToNoAvailability;
}
