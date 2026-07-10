import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checks/checks.dart';
import 'package:tilawa/core/services/prayer_widget_schedule_sync.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PrayerTimeEntity dayAt(DateTime base) => PrayerTimeEntity(
    date: base,
    fajr: base.add(const Duration(hours: 4)),
    sunrise: base.add(const Duration(hours: 6)),
    dhuhr: base.add(const Duration(hours: 12)),
    asr: base.add(const Duration(hours: 15)),
    maghrib: base.add(const Duration(hours: 18)),
    isha: base.add(const Duration(hours: 20)),
    midnight: base.add(const Duration(hours: 23)),
    lastThird: base.add(const Duration(hours: 2)),
  );

  group('PrayerWidgetScheduleSync', () {
    late List<MethodCall> calls;
    late PrayerWidgetScheduleSync sync;
    const channel = MethodChannel('com.tilawa.app/prayer_adhan_test');

    setUp(() {
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
      sync = PrayerWidgetScheduleSync(
        channel: channel,
        isSupportedOverride: true,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('pushes schema-v1 snapshot with all five prayers per day', () async {
      final day1 = dayAt(DateTime(2026, 7, 11));
      final day2 = dayAt(DateTime(2026, 7, 12));

      await sync.push(days: [day1, day2], locationName: 'Cairo');

      check(calls.length).equals(1);
      check(calls.single.method).equals('updatePrayerWidgetSchedule');
      final args = calls.single.arguments as Map<Object?, Object?>;
      final decoded =
          jsonDecode(args['json']! as String) as Map<String, dynamic>;
      check(
        decoded['version'] as int,
      ).equals(PrayerWidgetScheduleSync.schemaVersion);
      check(decoded['locationName'] as String).equals('Cairo');
      final days = decoded['days'] as List<dynamic>;
      check(days.length).equals(2);
      final first = days.first as Map<String, dynamic>;
      check(first['fajr'] as int).equals(day1.fajr.millisecondsSinceEpoch);
      check(first['isha'] as int).equals(day1.isha.millisecondsSinceEpoch);
    });

    test('no-ops when unsupported', () async {
      final unsupported = PrayerWidgetScheduleSync(
        channel: channel,
        isSupportedOverride: false,
      );
      await unsupported.push(days: [dayAt(DateTime(2026, 7, 11))]);
      check(calls).isEmpty();
    });

    test('no-ops for an empty schedule', () async {
      await sync.push(days: const []);
      check(calls).isEmpty();
    });

    test('swallows platform exceptions (best-effort contract)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'WIDGET_UPDATE_FAILED');
          });
      // Must not throw.
      await sync.push(days: [dayAt(DateTime(2026, 7, 11))]);
    });
  });
}
