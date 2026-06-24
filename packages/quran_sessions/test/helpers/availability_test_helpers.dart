import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'fakes/fake_booked_slot_lock_repository.dart';
import 'fakes/fake_session_repository.dart';
import 'fakes/fake_teacher_profile_repository.dart';
import 'fakes/fake_user_profile_repository.dart';

/// In-memory [ScheduleRepository] for tests.
class FakeScheduleRepository implements ScheduleRepository {
  WeeklySchedule? schedule;
  final List<AvailabilityOverride> overrides = [];
  QuranSessionsFailure? failWith;
  int getOverridesCallCount = 0;
  int getOverrideByDateCallCount = 0;
  bool? lastGetOverridesHadDateBounds;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(schedule);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    if (failWith != null) return Left(failWith!);
    this.schedule = schedule;
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    getOverridesCallCount++;
    lastGetOverridesHadDateBounds = from != null || to != null;
    if (failWith != null) return Left(failWith!);
    final fromDate = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final toDate = to == null ? null : DateTime(to.year, to.month, to.day);
    final filtered = overrides.where((o) {
      if (fromDate != null && o.date.isBefore(fromDate)) return false;
      if (toDate != null && !o.date.isBefore(toDate)) return false;
      return true;
    }).toList();
    return Right(filtered);
  }

  @override
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
    getOverrideByDateCallCount++;
    if (failWith != null) return Left(failWith!);
    for (final override in overrides) {
      if (override.dateKey == dateKey) return Right(override);
    }
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async {
    if (failWith != null) return Left(failWith!);
    overrides
      ..removeWhere((o) => o.dateKey == override.dateKey)
      ..add(override);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  ) async {
    if (failWith != null) return Left(failWith!);
    overrides.removeWhere((o) => o.dateKey == dateKey);
    return const Right(null);
  }
}

/// In-memory scheduling policy config for tests.
class FakeMarketSchedulingConfigRepository
    implements MarketSchedulingConfigRepository {
  MarketSchedulingConfig global = MarketSchedulingConfig.defaults;
  final Map<String, MarketSchedulingConfig> marketOverrides = {};

  @override
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>>
  getGlobal() async {
    return Right(global);
  }

  @override
  Future<Either<QuranSessionsFailure, MarketSchedulingConfig>> getForMarket(
    String countryCode,
  ) async {
    final override = marketOverrides[countryCode];
    if (override == null) {
      return Left(NotFoundFailure('MarketSchedulingConfig($countryCode)'));
    }
    return Right(override);
  }
}

/// Minimal [TeacherDashboardSuccess] for bloc/widget tests.
TeacherDashboardSuccess seedTeacherDashboardSuccess({
  List<QuranSession> upcomingSessions = const [],
  List<TeacherAvailability> availability = const [],
  MarketSchedulingConfig schedulingConfig = MarketSchedulingConfig.defaults,
  List<TeacherAvailability>? thisWeekAvailability,
  List<TeacherAvailability>? nextWeekAvailability,
  bool showFridayReviewBanner = false,
  String? fridayReviewNextWeekKey,
  String? dismissedFridayReminderWeekKey,
  String teacherTimezone = 'Africa/Cairo',
  String? marketCountryCode,
  bool isUpdatingAvailability = false,
  bool isRefreshing = false,
  Map<String, PendingSlotDelete> pendingDeletes = const {},
  String? undoableSlotId,
  QuranSessionsFailure? slotFailure,
  int? refreshDiscardedPendingCount,
}) {
  return TeacherDashboardSuccess(
    upcomingSessions: upcomingSessions,
    availability: availability,
    schedulingConfig: schedulingConfig,
    thisWeekAvailability: thisWeekAvailability ?? availability,
    nextWeekAvailability: nextWeekAvailability ?? const [],
    showFridayReviewBanner: showFridayReviewBanner,
    fridayReviewNextWeekKey: fridayReviewNextWeekKey,
    dismissedFridayReminderWeekKey: dismissedFridayReminderWeekKey,
    teacherTimezone: teacherTimezone,
    marketCountryCode: marketCountryCode,
    isUpdatingAvailability: isUpdatingAvailability,
    isRefreshing: isRefreshing,
    pendingDeletes: pendingDeletes,
    undoableSlotId: undoableSlotId,
    slotFailure: slotFailure,
    refreshDiscardedPendingCount: refreshDiscardedPendingCount,
  );
}

/// Builds a [TeacherDashboardBloc] with in-memory scheduling policy deps.
TeacherDashboardBloc buildTestTeacherDashboardBloc({
  required FakeSessionRepository sessionRepo,
  required GetTeacherAvailabilityUseCase getAvailability,
  required BlockGeneratedSlotUseCase blockGeneratedSlot,
  required AvailabilityProvider availabilityProvider,
  required CancelSessionViaServerUseCase cancelSession,
  required CompleteSessionViaServerUseCase completeSession,
  required FakeScheduleRepository scheduleRepo,
  FakeMarketSchedulingConfigRepository? schedulingConfigRepo,
  FakeUserProfileRepository? userProfileRepo,
  FakeTeacherProfileRepository? teacherProfileRepo,
  FakeBookedSlotLockRepository? bookedSlotLockRepository,
  InMemoryFridayReviewReminderStore? fridayReminderStore,
  CommitTimerFactory? commitTimerFactory,
  Duration commitDelay = const Duration(days: 365),
  DateTime Function()? now,
  String teacherId = 'teacher_1',
}) {
  final configRepo =
      schedulingConfigRepo ?? FakeMarketSchedulingConfigRepository();
  final profiles = userProfileRepo ?? FakeUserProfileRepository();
  final teacherProfiles = teacherProfileRepo ?? FakeTeacherProfileRepository();
  final reminders = fridayReminderStore ?? InMemoryFridayReviewReminderStore();
  return TeacherDashboardBloc(
    getTeacherSessions: GetTeacherSessionsUseCase(sessionRepo),
    isSlotBooked: IsSlotBookedUseCase(
      bookedSlotLockRepository ?? FakeBookedSlotLockRepository(),
    ),
    getAvailability: getAvailability,
    blockGeneratedSlot: blockGeneratedSlot,
    availabilityProvider: availabilityProvider,
    cancelSession: cancelSession,
    completeSession: completeSession,
    getMarketSchedulingConfig: GetMarketSchedulingConfigUseCase(configRepo),
    getUserProfile: GetUserProfileUseCase(profiles),
    getWeeklySchedule: GetWeeklyScheduleUseCase(scheduleRepo),
    fridayReviewReminderStore: reminders,
    teacherProfileRepository: teacherProfiles,
    teacherId: teacherId,
    commitTimerFactory: commitTimerFactory,
    commitDelay: commitDelay,
    now: now,
  );
}

GetTeacherAvailabilityUseCase buildGetTeacherAvailabilityUseCase({
  required FakeScheduleRepository scheduleRepository,
  FakeBookedSlotLockRepository? bookedSlotLockRepository,
  FakeSessionRepository? sessionRepository,
  DateTime Function()? now,
}) {
  final locks = bookedSlotLockRepository ?? FakeBookedSlotLockRepository();
  if (bookedSlotLockRepository == null && sessionRepository != null) {
    for (final session in sessionRepository.sessions) {
      if (session.teacherId.isEmpty) continue;
      locks.seedHardLock(
        teacherId: session.teacherId,
        startUtc: session.startsAt.toUtc(),
      );
    }
  }
  return GetTeacherAvailabilityUseCase(
    scheduleRepository: scheduleRepository,
    bookedSlotLocks: locks,
    now: now,
  );
}

/// Wraps [GetTeacherAvailabilityUseCase] to count [call] invocations in tests.
class SpyGetTeacherAvailabilityUseCase extends GetTeacherAvailabilityUseCase {
  SpyGetTeacherAvailabilityUseCase({
    required super.scheduleRepository,
    required super.bookedSlotLocks,
    super.now,
  });

  int callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    return super.call(teacherId, from: from, to: to);
  }
}

WeeklySchedule makeWeeklySchedule({
  String teacherId = 'teacher_1',
  String timezone = 'Africa/Cairo',
  SlotDuration slotDuration = SlotDuration.thirty,
  Map<Weekday, List<TimeRange>>? rules,
  SchedulingPolicy policy = const SchedulingPolicy(
    minNoticeMinutes: 0,
    maxHorizonDays: 1000,
  ),
}) => WeeklySchedule(
  teacherId: teacherId,
  timezone: timezone,
  slotDuration: slotDuration,
  rules:
      rules ??
      {
        Weekday.saturday: const [
          TimeRange(start: LocalTime(9, 0), end: LocalTime(12, 0)),
        ],
      },
  policy: policy,
);
