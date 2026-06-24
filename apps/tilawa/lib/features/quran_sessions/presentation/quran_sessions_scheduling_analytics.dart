import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Resolves scheduling experiment params for a teacher's market.
Future<Map<String, Object>> resolveTeacherSchedulingAnalyticsBase(
  String teacherId,
) async {
  if (!getIt.isRegistered<GetMarketSchedulingConfigUseCase>() ||
      !getIt.isRegistered<GetUserProfileUseCase>()) {
    return const {};
  }
  var ownerUserId = teacherId;
  if (getIt.isRegistered<TeacherProfileRepository>()) {
    final teacherProfile = await getIt<TeacherProfileRepository>()
        .getProfileById(teacherId);
    ownerUserId = teacherProfile.fold(
      (_) => teacherId,
      (profile) => profile.userId,
    );
  }
  final profileResult = await getIt<GetUserProfileUseCase>()(ownerUserId);
  final countryCode = profileResult.fold(
    (_) => null,
    (profile) => profile.countryCode,
  );
  final config = await getIt<GetMarketSchedulingConfigUseCase>()(
    countryCode: countryCode,
  );
  return {
    'scheduling_mode': config.schedulingMode.storageKey,
    'policy_version': config.policyVersion,
    'market_code': ?countryCode,
  };
}

/// Host wiring for scheduling experiment analytics.
QuranSessionsSchedulingAnalyticsCallbacks
quranSessionsSchedulingAnalyticsCallbacks() {
  if (!getIt.isRegistered<AnalyticsService>()) {
    return const QuranSessionsSchedulingAnalyticsCallbacks();
  }
  final AnalyticsService analytics = getIt<AnalyticsService>();
  return QuranSessionsSchedulingAnalyticsCallbacks(
    onWeekViewOpened: (parameters) => analytics.logEvent(
      AnalyticsEvents.weekViewOpened,
      parameters: parameters,
    ),
    onFridayReviewBannerShown: (parameters) => analytics.logEvent(
      AnalyticsEvents.fridayReviewBannerShown,
      parameters: parameters,
    ),
    onFridayReviewBannerTapped: (parameters) => analytics.logEvent(
      AnalyticsEvents.fridayReviewBannerTapped,
      parameters: parameters,
    ),
    onFridayReviewBannerDismissed: (parameters) => analytics.logEvent(
      AnalyticsEvents.fridayReviewBannerDismissed,
      parameters: parameters,
    ),
    onWeeklyTemplateOpened: (parameters) => analytics.logEvent(
      AnalyticsEvents.weeklyTemplateOpened,
      parameters: parameters,
    ),
    onWeeklyTemplateSaved: (parameters) => analytics.logEvent(
      AnalyticsEvents.weeklyTemplateSaved,
      parameters: parameters,
    ),
    onBookingLostDueToNoAvailability: (parameters) => analytics.logEvent(
      AnalyticsEvents.bookingLostDueToNoAvailability,
      parameters: parameters,
    ),
  );
}
