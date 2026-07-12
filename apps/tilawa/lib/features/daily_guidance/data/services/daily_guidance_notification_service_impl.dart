import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/daily_guidance_preferences.dart';
import '../../domain/usecases/schedule_daily_guidance_use_case.dart';

@LazySingleton(as: DailyGuidanceNotificationService)
class DailyGuidanceNotificationServiceImpl
    implements DailyGuidanceNotificationService {
  final INotificationDispatcher _dispatcher;

  static const String _channelId = 'daily_guidance_channel';
  static const String _channelName = 'Daily Guidance';
  static const String _channelDescription =
      'Daily Islamic reminders and guidance.';
  static const int _notificationId = 19992; // Unique ID

  DailyGuidanceNotificationServiceImpl(this._dispatcher);

  @override
  Future<void> scheduleDailyTrigger(
    DailyGuidancePreferences preferences,
  ) async {
    final plugin = _dispatcher.notificationsPlugin;

    // First cancel any existing schedule
    await cancelDailyTrigger();

    if (!preferences.enabled) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance:
          Importance.low, // It's just a background trigger payload, but wait.
      // If we use it as a background trigger, we could use a silent notification.
      // But actually, the prompt says we should schedule the notification itself?
      // Wait, "The system will schedule a daily local notification at the preferred local time."
      // BUT we need the content of the notification to change daily!
      // Local notifications can't easily fetch dynamic content natively.
      // Tilawa uses a local data source. We can schedule a generic "Your daily guidance is ready"
      // OR we schedule a daily background task to update the notification?
      // Actually, standard flutter local notifications let us schedule an exact daily time,
      // but the text is static unless we use workmanager or we schedule the next 7 days in advance.
    );

    // TODO: implement advanced scheduling (like pre-scheduling 7 days with content).
    // For MVP phase 3, we just schedule a generic daily repeating notification to act as a trigger
    // or generic reminder. Then when tapped, it deep links to the screen which loads the today item.
    // Let's schedule it to run daily at the preferred time.

    // A generic "Daily Guidance is ready" notification
    await plugin.zonedSchedule(
      id: _notificationId,
      title: 'نفحة اليوم | Daily Guidance',
      body: "Open to see today's guidance",
      scheduledDate: _nextInstanceOfTime(
        preferences.preferredLocalTime.hour,
        preferences.preferredLocalTime.minute,
      ),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_guidance_payload',
    );
  }

  @override
  Future<void> cancelDailyTrigger() async {
    await _dispatcher.notificationsPlugin.cancel(id: _notificationId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
