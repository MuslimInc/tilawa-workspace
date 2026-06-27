import 'package:flutter/foundation.dart';

/// Reserved local-notification ids for the developer Notification Debug Lab.
///
/// Range 900000–909999 is inside the download id block [100000, 1000000);
/// routing resolves payload handlers (athkar/prayer/…) ahead of the download
/// id-range when both match.
@immutable
class NotificationDebugConstants {
  const NotificationDebugConstants._();

  static const int idRangeStart = 900000;
  static const int idRangeEnd = 909999;

  static const int morningAthkar = 900001;
  static const int eveningAthkar = 900002;
  static const int prayer = 900003;
  static const int tasbeeh = 900004;
  static const int download = 900005;
  static const int invalidPayloadId = 900010;
  static const int emptyPayload = 900011;
  static const int payloadOnlyPrayer = 900012;
  static const int sameIdSamePayload = 900013;
  static const int sameIdDifferentPayloadA = 900014;
  static const int sameIdDifferentPayloadB = 900014;
  static const int differentIdSamePayload = 900015;

  static const String morningAthkarPayloadPrefix = 'morning_athkar_';
  static const String eveningAthkarPayloadPrefix = 'evening_athkar_';
  static const String tasbeehPayloadPrefix = 'tasbeeh_reminder_';

  static String morningAthkarPayload({String suffix = 'debug_lab'}) =>
      '$morningAthkarPayloadPrefix$suffix';

  static String eveningAthkarPayload({String suffix = 'debug_lab'}) =>
      '$eveningAthkarPayloadPrefix$suffix';

  static String settingsPayload() => '{"type":"settings"}';

  static String invalidPayloadValue() => 'not-json-and-not-athkar';

  static String prayerPayload({String prayerKey = 'fajr'}) =>
      '{"type":"prayer","prayer_key":"$prayerKey","prayer_name":"$prayerKey"}';

  static String downloadPayload() =>
      '{"type":"download","reciterId":"1","reciterName":"Debug Reciter"}';

  static String tasbeehPayload({String dhikrId = 'debug_dhikr'}) =>
      '$tasbeehPayloadPrefix$dhikrId';
}

enum NotificationDebugMechanism {
  realLocalNotification,
  dispatcherSimulation,
  bootstrapLaunchProbe,
  dedupOnly,
  clearPidScope,
}

@immutable
class NotificationDebugActionSpec {
  const NotificationDebugActionSpec({
    required this.key,
    required this.notificationId,
    required this.payload,
    required this.expectedRoute,
    required this.expectedBehavior,
    required this.mechanism,
    this.scheduleDelay,
  });

  final String key;
  final int? notificationId;
  final String? payload;
  final String expectedRoute;
  final String expectedBehavior;
  final NotificationDebugMechanism mechanism;
  final Duration? scheduleDelay;
}
