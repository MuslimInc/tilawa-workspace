import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_notification_schedule_repository.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_notification_permission_status.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late _FakeScheduleRepository scheduleRepository;
  late _FakePrayerPermissionStatus permissionStatus;
  late _FakePrayerTimesRepository prayerTimesRepository;
  late _FakePrayerAdhanNotificationService notificationService;
  late _FakeAdhanAlarmPlayer adhanPlayer;
  late EnsurePrayerNotificationsScheduledUseCase useCase;

  final DateTime now = DateTime(2026, 5, 1, 12);
  const PrayerSettingsEntity settings = PrayerSettingsEntity(
    savedLatitude: 30,
    savedLongitude: 31,
  );

  setUp(() {
    scheduleRepository = _FakeScheduleRepository();
    permissionStatus = _FakePrayerPermissionStatus();
    prayerTimesRepository = _FakePrayerTimesRepository(settings: settings);
    notificationService = _FakePrayerAdhanNotificationService();
    adhanPlayer = _FakeAdhanAlarmPlayer();
    useCase = EnsurePrayerNotificationsScheduledUseCase(
      scheduleRepository,
      permissionStatus,
      prayerTimesRepository,
      SchedulePrayerNotificationsUseCase(
        notificationService,
        prayerTimesRepository,
      ),
      adhanPlayer,
    );
  });

  group('EnsurePrayerNotificationsScheduledUseCase', () {
    test('skips when remaining schedule window is above threshold', () async {
      scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
        scheduledFrom: now,
        scheduledUntil: now.add(const Duration(days: 8)),
        scheduledAt: now,
        scheduledCount: 70,
      );

      final result = await useCase(now: now);
      final ensureResult = _unwrap(result);

      expect(
        ensureResult.action,
        PrayerNotificationEnsureAction.skippedWindowSufficient,
      );
      expect(notificationService.scheduleCalls, 0);
    });

    test(
      'reschedules when remaining schedule window is below threshold',
      () async {
        scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
          scheduledFrom: now,
          scheduledUntil: now.add(const Duration(days: 6, hours: 23)),
          scheduledAt: now,
          scheduledCount: 70,
        );

        final result = await useCase(now: now);
        final ensureResult = _unwrap(result);

        expect(ensureResult.action, PrayerNotificationEnsureAction.rescheduled);
        expect(notificationService.scheduleCalls, 1);
        expect(notificationService.lastForceReschedule, isTrue);
      },
    );

    test('reschedules when no schedule snapshot exists', () async {
      final result = await useCase(now: now);
      final ensureResult = _unwrap(result);

      expect(ensureResult.action, PrayerNotificationEnsureAction.rescheduled);
      expect(notificationService.scheduleCalls, 1);
    });

    test('forceReschedule bypasses a sufficient schedule window', () async {
      scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
        scheduledFrom: now,
        scheduledUntil: now.add(const Duration(days: 13)),
        scheduledAt: now,
        scheduledCount: 70,
      );

      final result = await useCase(now: now, forceReschedule: true);
      final ensureResult = _unwrap(result);

      expect(ensureResult.action, PrayerNotificationEnsureAction.rescheduled);
      expect(notificationService.scheduleCalls, 1);
    });

    test(
      'clears snapshot and skips when notification permission is revoked',
      () async {
        permissionStatus.allowed = false;
        scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
          scheduledFrom: now,
          scheduledUntil: now.add(const Duration(days: 13)),
          scheduledAt: now,
          scheduledCount: 70,
        );

        final result = await useCase(now: now);
        final ensureResult = _unwrap(result);

        expect(
          ensureResult.action,
          PrayerNotificationEnsureAction.skippedPermissionDenied,
        );
        expect(scheduleRepository.clearCalls, 1);
        expect(notificationService.scheduleCalls, 0);
      },
    );

    test('skips when there is no saved location', () async {
      prayerTimesRepository.settings = const PrayerSettingsEntity();

      final result = await useCase(now: now);
      final ensureResult = _unwrap(result);

      expect(
        ensureResult.action,
        PrayerNotificationEnsureAction.skippedNoSavedLocation,
      );
      expect(notificationService.scheduleCalls, 0);
    });

    test(
      'uses last resolved location when manual saved location is absent',
      () async {
        prayerTimesRepository.settings = const PrayerSettingsEntity(
          lastResolvedLatitude: 40,
          lastResolvedLongitude: 41,
          fajrNotification: PrayerNotificationSettings(
            mode: PrayerAlertMode.notification,
          ),
        );

        final result = await useCase(now: now, forceReschedule: true);
        final ensureResult = _unwrap(result);

        expect(ensureResult.action, PrayerNotificationEnsureAction.rescheduled);
        expect(notificationService.scheduleCalls, 1);
        expect(prayerTimesRepository.lastRangeLatitude, 40);
        expect(prayerTimesRepository.lastRangeLongitude, 41);
      },
    );

    test('re-marks dirty flag when forced recovery has no location', () async {
      prayerTimesRepository.settings = const PrayerSettingsEntity();

      final result = await useCase(now: now, forceReschedule: true);
      final ensureResult = _unwrap(result);

      expect(
        ensureResult.action,
        PrayerNotificationEnsureAction.skippedNoSavedLocation,
      );
      expect(adhanPlayer.markNeedsRescheduleCalls, 1);
      expect(notificationService.scheduleCalls, 0);
    });

    test('skips when every prayer notification is disabled', () async {
      prayerTimesRepository.settings = const PrayerSettingsEntity(
        savedLatitude: 30,
        savedLongitude: 31,
        fajrNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
        dhuhrNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
        asrNotification: PrayerNotificationSettings(mode: PrayerAlertMode.none),
        maghribNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
        ishaNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
      );

      final result = await useCase(now: now);
      final ensureResult = _unwrap(result);

      expect(
        ensureResult.action,
        PrayerNotificationEnsureAction.skippedNotificationsDisabled,
      );
      expect(scheduleRepository.clearCalls, 1);
      expect(notificationService.scheduleCalls, 0);
    });
  });
}

PrayerNotificationEnsureResult _unwrap(
  Either<Failure, PrayerNotificationEnsureResult> result,
) {
  return result.fold(
    (failure) => fail('Expected Right, got ${failure.message}'),
    (value) => value,
  );
}

class _FakeScheduleRepository implements PrayerNotificationScheduleRepository {
  PrayerNotificationScheduleSnapshot? snapshot;
  int clearCalls = 0;

  @override
  Future<void> clearSnapshot() async {
    clearCalls++;
    snapshot = null;
  }

  @override
  Future<PrayerNotificationScheduleSnapshot?> loadSnapshot() async => snapshot;

  @override
  Future<void> saveSnapshot(PrayerNotificationScheduleSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}

class _FakePrayerPermissionStatus
    implements PrayerNotificationPermissionStatus {
  bool allowed = true;

  @override
  Future<bool> areNotificationsAllowed() async => allowed;
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  _FakePrayerTimesRepository({required this.settings});

  PrayerSettingsEntity settings;
  double? lastRangeLatitude;
  double? lastRangeLongitude;

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async {
    return _prayerDay(date, latitude, longitude);
  }

  @override
  Future<List<PrayerTimeEntity>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerSettingsEntity settings,
  }) async {
    lastRangeLatitude = latitude;
    lastRangeLongitude = longitude;
    return <PrayerTimeEntity>[_prayerDay(startDate, latitude, longitude)];
  }

  @override
  Future<List<PrayerTimeEntity>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required PrayerSettingsEntity settings,
  }) async {
    return <PrayerTimeEntity>[];
  }

  @override
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
    String? localeIdentifier,
  }) async {
    return LocationResult(latitude: 0, longitude: 0);
  }

  @override
  Future<String?> getLocationName({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) async {
    return null;
  }

  @override
  Future<String?> getCountryCode({
    required double latitude,
    required double longitude,
  }) async {
    return null;
  }

  @override
  Future<bool> hasLocationPermission() async => false;

  @override
  Future<bool> requestLocationPermission({
    bool allowOpenSettings = false,
  }) async => false;

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {
    this.settings = settings;
  }

  @override
  Future<PrayerSettingsEntity> loadSettings() async => settings;
}

class _FakePrayerAdhanNotificationService
    implements IPrayerAdhanNotificationService {
  int scheduleCalls = 0;
  bool? lastForceReschedule;

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  }) async {
    scheduleCalls++;
    lastForceReschedule = forceReschedule;
  }

  @override
  Future<void> cancelAllPrayerNotifications() async {}

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> fireTestNotification({
    required PrayerType prayer,
    required bool playAdhan,
  }) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> debugScheduleTestAdhan() async {}
}

class _FakeAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  int markNeedsRescheduleCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();

  @override
  Future<void> flushPendingNotificationTap() async {}

  @override
  Future<String?> pullPendingNotificationTapPayload() async => null;

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
    String? locationName,
    String? languageCode,
  }) async {
    return true;
  }

  @override
  Future<bool> playAdhanNow({
    required int id,
    required String prayerName,
    required String prayerKey,
    String? sound,
    String? locationName,
    String? languageCode,
  }) async => false;

  @override
  Future<void> cancelAdhan(int id, {String? prayerName}) async {}

  @override
  Future<void> cancelAllAdhans() async {}

  @override
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {}

  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async => false;

  @override
  Future<void> markNeedsReschedule() async {
    markNeedsRescheduleCalls++;
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<String?> manufacturer() async => null;

  @override
  Future<void> stopCurrentAdhan() async {}

  @override
  Future<bool> isAdhanPlaying() async => false;

  @override
  Future<String?> getActiveAdhanPayload() async => null;
}

PrayerTimeEntity _prayerDay(DateTime date, double latitude, double longitude) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  return PrayerTimeEntity(
    date: day,
    fajr: day.add(const Duration(hours: 5)),
    sunrise: day.add(const Duration(hours: 6)),
    dhuhr: day.add(const Duration(hours: 12)),
    asr: day.add(const Duration(hours: 15)),
    maghrib: day.add(const Duration(hours: 18)),
    isha: day.add(const Duration(hours: 20)),
    midnight: day.add(const Duration(hours: 23)),
    lastThird: day.add(const Duration(hours: 2)),
    latitude: latitude,
    longitude: longitude,
  );
}
