import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

void _logTeacherApplicationEvent(String name) {
  if (!getIt.isRegistered<AnalyticsService>()) return;
  getIt<AnalyticsService>().logEvent(name);
}

void logTeacherApplicationEntrySeen() =>
    _logTeacherApplicationEvent(AnalyticsEvents.teacherApplicationEntrySeen);

void logTeacherApplicationEntryTapped() => _logTeacherApplicationEvent(
  AnalyticsEvents.teacherApplicationEntryTapped,
);

void logTeacherApplicationFormOpened() => _logTeacherApplicationEvent(
  AnalyticsEvents.teacherApplicationFormOpened,
);

void logTeacherApplicationFormFailed() => _logTeacherApplicationEvent(
  AnalyticsEvents.teacherApplicationFormFailed,
);
