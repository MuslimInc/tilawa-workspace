import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_notification_schedule_repository.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_notification_permission_status.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStartupTasks startupTasks;
  late _FakePrayerAdhanNotificationService notificationService;
  late _FakeAdhanAlarmPlayer adhanPlayer;
  late _FakeScheduleRepository scheduleRepository;
  late _FakePrayerPermissionStatus permissionStatus;
  late _FakePrayerTimesRepository prayerTimesRepository;

  final DateTime now = DateTime(2026, 7, 11, 12);

  Future<void> registerPrayerStartupDependencies() async {
    final GetIt container = getIt;
    if (container.isRegistered<IPrayerAdhanNotificationService>()) {
      await container.unregister<IPrayerAdhanNotificationService>();
    }
    if (container.isRegistered<IAdhanAlarmPlayer>()) {
      await container.unregister<IAdhanAlarmPlayer>();
    }
    if (container.isRegistered<EnsurePrayerNotificationsScheduledUseCase>()) {
      await container.unregister<EnsurePrayerNotificationsScheduledUseCase>();
    }

    container.registerSingleton<IPrayerAdhanNotificationService>(
      notificationService,
    );
    container.registerSingleton<IAdhanAlarmPlayer>(adhanPlayer);
    container.registerSingleton<EnsurePrayerNotificationsScheduledUseCase>(
      EnsurePrayerNotificationsScheduledUseCase(
        scheduleRepository,
        permissionStatus,
        prayerTimesRepository,
        SchedulePrayerNotificationsUseCase(
          notificationService,
          prayerTimesRepository,
        ),
        adhanPlayer,
      ),
    );
  }

  setUp(() async {
    startupTasks = AppStartupTasks(
      launchConfig: const AppLaunchConfig(prayerNotificationsInit: true),
    );
    notificationService = _FakePrayerAdhanNotificationService();
    adhanPlayer = _FakeAdhanAlarmPlayer();
    scheduleRepository = _FakeScheduleRepository();
    permissionStatus = _FakePrayerPermissionStatus();
    prayerTimesRepository = _FakePrayerTimesRepository();

    await registerPrayerStartupDependencies();
  });

  tearDown(() async {
    final GetIt container = getIt;
    if (container.isRegistered<IPrayerAdhanNotificationService>()) {
      await container.unregister<IPrayerAdhanNotificationService>();
    }
    if (container.isRegistered<IAdhanAlarmPlayer>()) {
      await container.unregister<IAdhanAlarmPlayer>();
    }
    if (container.isRegistered<EnsurePrayerNotificationsScheduledUseCase>()) {
      await container.unregister<EnsurePrayerNotificationsScheduledUseCase>();
    }
  });

  test(
    'startup skips full prayer recompute when schedule window is healthy',
    () async {
      scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
        scheduledFrom: now,
        scheduledUntil: now.add(const Duration(days: 10)),
        scheduledAt: now,
        scheduledCount: 70,
      );

      await startupTasks.initializePrayerNotifications();

      expect(notificationService.initializeCalls, 1);
      expect(adhanPlayer.consumeNeedsRescheduleAfterBootCalls, 1);
      expect(prayerTimesRepository.getPrayerTimesForRangeCalls, 0);
      expect(notificationService.scheduleCalls, 0);
    },
  );

  test(
    'startup still forces reschedule after boot/time change invalidation',
    () async {
      scheduleRepository.snapshot = PrayerNotificationScheduleSnapshot(
        scheduledFrom: now,
        scheduledUntil: now.add(const Duration(days: 10)),
        scheduledAt: now,
        scheduledCount: 70,
      );
      adhanPlayer.consumeNeedsRescheduleAfterBootValue = true;

      await startupTasks.initializePrayerNotifications();

      expect(notificationService.initializeCalls, 1);
      expect(adhanPlayer.consumeNeedsRescheduleAfterBootCalls, 1);
      expect(prayerTimesRepository.getPrayerTimesForRangeCalls, 1);
      expect(notificationService.scheduleCalls, 1);
      expect(notificationService.lastForceReschedule, isTrue);
    },
  );
}

class _FakeScheduleRepository implements PrayerNotificationScheduleRepository {
  PrayerNotificationScheduleSnapshot? snapshot;

  @override
  Future<void> clearSnapshot() async {
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
  @override
  Future<bool> areNotificationsAllowed() async => true;
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  int getPrayerTimesForRangeCalls = 0;

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
    getPrayerTimesForRangeCalls++;
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
  Future<PrayerSettingsEntity> loadSettings() async {
    return const PrayerSettingsEntity(
      savedLatitude: 30,
      savedLongitude: 31,
    );
  }

  @override
  Future<bool> requestLocationPermission({
    bool allowOpenSettings = false,
  }) async => false;

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {}
}

class _FakePrayerAdhanNotificationService
    implements IPrayerAdhanNotificationService {
  int initializeCalls = 0;
  int scheduleCalls = 0;
  bool? lastForceReschedule;

  @override
  Future<void> cancelAllPrayerNotifications() async {}

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<AdhanDebugScheduleResult> debugScheduleTestAdhan() async =>
      const AdhanDebugScheduleResult.native(exactAlarmAvailable: true);

  @override
  Future<void> fireTestNotification({
    required PrayerType prayer,
    required bool playAdhan,
  }) async {}

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  }) async {
    scheduleCalls++;
    lastForceReschedule = forceReschedule;
  }
}

class _FakeAdhanAlarmPlayer implements IAdhanAlarmPlayer {
  bool consumeNeedsRescheduleAfterBootValue = false;
  int consumeNeedsRescheduleAfterBootCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<String> get onNotificationTapped => const Stream<String>.empty();

  @override
  Future<void> cancelAdhan(int id, {String? prayerName}) async {}

  @override
  Future<void> cancelAllAdhans() async {}

  @override
  Future<bool> consumeNeedsRescheduleAfterBoot() async {
    consumeNeedsRescheduleAfterBootCalls++;
    final bool value = consumeNeedsRescheduleAfterBootValue;
    consumeNeedsRescheduleAfterBootValue = false;
    return value;
  }

  @override
  Future<void> flushPendingNotificationTap() async {}

  @override
  Future<String?> getActiveAdhanPayload() async => null;

  @override
  Future<bool> isAdhanPlaying() async => false;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<void> markNeedsReschedule() async {}

  @override
  Future<String?> manufacturer() async => null;

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
  Future<void> persistPendingAlarms(List<PendingAdhanAlarm> alarms) async {}

  @override
  Future<String?> pullPendingNotificationTapPayload() async => null;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<bool> scheduleAdhan({
    required int id,
    required DateTime scheduledTime,
    required String prayerName,
    required String prayerKey,
    String? sound,
    String? locationName,
    String? languageCode,
  }) async => true;

  @override
  Future<void> stopCurrentAdhan() async {}
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
