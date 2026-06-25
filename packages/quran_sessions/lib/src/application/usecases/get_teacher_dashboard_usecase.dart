import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/entities/generated_slot.dart';
import '../../domain/entities/market_scheduling_config.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../cache/cache_freshness_policy.dart';
import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';
import '../../domain/repositories/booked_slot_lock_repository.dart';
import '../../domain/repositories/market_scheduling_config_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/services/slot_generator.dart';
import '../../domain/services/teacher_availability_sort.dart';

class TeacherDashboardResult {
  const TeacherDashboardResult({
    required this.profile,
    required this.schedulingConfig,
    required this.schedule,
    required this.upcomingSessions,
    required this.availability,
  });

  final UserProfile profile;
  final MarketSchedulingConfig schedulingConfig;
  final WeeklySchedule? schedule;
  final List<QuranSession> upcomingSessions;
  final List<TeacherAvailability> availability;
}

class GetTeacherDashboardUseCase {
  const GetTeacherDashboardUseCase({
    required this.userProfileRepository,
    required this.marketSchedulingConfigRepository,
    required this.scheduleRepository,
    required this.sessionRepository,
    required this.teacherProfileRepository,
    required this.bookedSlotLocks,
    this.slotGenerator = const SlotGenerator(),
    required this.cacheStore,
    this.currentTime,
  });

  final UserProfileRepository userProfileRepository;
  final MarketSchedulingConfigRepository marketSchedulingConfigRepository;
  final ScheduleRepository scheduleRepository;
  final SessionRepository sessionRepository;
  final TeacherProfileRepository teacherProfileRepository;
  final BookedSlotLockRepository bookedSlotLocks;
  final SlotGenerator slotGenerator;
  final QuranSessionCacheStore cacheStore;
  final DateTime Function()? currentTime;

  Future<Either<QuranSessionsFailure, TeacherDashboardResult>> call({
    required String teacherProfileId,
    required DateTime now,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      cacheStore.remove(
        SessionCacheKey.teacherDashboardSessions(teacherProfileId),
      );
      cacheStore.remove(SessionCacheKey.teacherAvailability(teacherProfileId));
      cacheStore.remove(SessionCacheKey.teacherProfileById(teacherProfileId));
      cacheStore.remove(SessionCacheKey.teacherSchedule(teacherProfileId));
    }

    try {
      final teacherProfile = await cacheStore.getOrFetch<TeacherProfile>(
        key: SessionCacheKey.teacherProfileById(teacherProfileId),
        ttl: CacheFreshnessPolicy.teacherProfileTtl,
        fetcher: () async {
          final res = await teacherProfileRepository.getProfileById(
            teacherProfileId,
          );
          return res.fold((f) => throw f, (p) => p);
        },
      );

      final ownerUserId = teacherProfile.userId.isNotEmpty
          ? teacherProfile.userId
          : teacherProfileId;

      final userProfile = await cacheStore.getOrFetch<UserProfile>(
        key: SessionCacheKey.teacherProfileByUserId(ownerUserId),
        ttl: CacheFreshnessPolicy.teacherProfileTtl,
        fetcher: () async {
          final res = await userProfileRepository.getProfile(ownerUserId);
          return res.fold((f) => throw f, (p) => p);
        },
      );

      final countryCode = userProfile.countryCode;
      final schedulingConfig = await _resolveSchedulingConfig(countryCode);

      final schedule = await cacheStore.getOrFetch<WeeklySchedule?>(
        key: SessionCacheKey.teacherSchedule(teacherProfileId),
        ttl: CacheFreshnessPolicy.weeklyScheduleTtl,
        fetcher: () async {
          final res = await scheduleRepository.getSchedule(teacherProfileId);
          return res.fold((f) => throw f, (s) => s);
        },
      );

      final upcomingSessions = await cacheStore.getOrFetch<List<QuranSession>>(
        key: SessionCacheKey.teacherDashboardSessions(teacherProfileId),
        ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
        fetcher: () async {
          final res = await sessionRepository.getTeacherUpcomingSessions(
            teacherProfileId,
          );
          return res.fold((f) => throw f, (s) => s);
        },
      );

      final horizonDays = schedulingConfig.bookingHorizonDays < 14
          ? schedulingConfig.bookingHorizonDays
          : 14;
      final horizon = Duration(days: horizonDays);

      final availability = await cacheStore
          .getOrFetch<List<TeacherAvailability>>(
            key: SessionCacheKey.teacherAvailability(teacherProfileId),
            ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
            fetcher: () => _loadAvailability(
              teacherProfileId: teacherProfileId,
              schedule: schedule,
              from: now,
              to: now.add(horizon),
            ),
          );

      return Right(
        TeacherDashboardResult(
          profile: userProfile,
          schedulingConfig: schedulingConfig,
          schedule: schedule,
          upcomingSessions: upcomingSessions,
          availability: availability,
        ),
      );
    } on QuranSessionsFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownFailure());
    }
  }

  Future<List<TeacherAvailability>> _loadAvailability({
    required String teacherProfileId,
    required WeeklySchedule? schedule,
    required DateTime from,
    required DateTime to,
  }) async {
    if (schedule == null || schedule.isEmpty) {
      return const [];
    }

    final overrideQueryTo = DateTime(to.year, to.month, to.day).add(
      const Duration(days: 1),
    );
    final overridesResult = await scheduleRepository.getOverrides(
      teacherProfileId,
      from: from,
      to: overrideQueryTo,
    );
    final overrides = overridesResult.fold((f) => throw f, (value) => value);

    final bookedStartsResult = await bookedSlotLocks.getActiveBookedStarts(
      teacherProfileId,
      windowStart: from,
      windowEnd: to,
      now: currentTime?.call() ?? DateTime.now(),
    );
    final bookedStarts = bookedStartsResult.fold(
      (f) => throw f,
      (value) => value,
    );

    final generated = slotGenerator.generate(
      schedule: schedule,
      overrides: overrides,
      bookedStartsUtc: bookedStarts,
      windowStart: from,
      windowEnd: to,
      now: currentTime?.call() ?? DateTime.now(),
    );

    return sortTeacherAvailabilityByStart(
      generated.map(_toTeacherAvailability).toList(),
    );
  }

  TeacherAvailability _toTeacherAvailability(GeneratedSlot slot) {
    return TeacherAvailability(
      slotId: slot.slotId,
      teacherId: slot.teacherId,
      startsAt: slot.startUtc,
      endsAt: slot.endUtc,
      isBooked: false,
    );
  }

  /// Resolves the effective scheduling config for [countryCode].
  ///
  /// Falls back to the global config when the market has no override doc,
  /// mirroring [GetMarketSchedulingConfigUseCase]'s resolution strategy.
  Future<MarketSchedulingConfig> _resolveSchedulingConfig(
    String? countryCode,
  ) async {
    if (countryCode != null && countryCode.isNotEmpty) {
      final market = await marketSchedulingConfigRepository.getForMarket(
        countryCode,
      );
      final override = market.fold((_) => null, (c) => c);
      if (override != null) return override;
    }
    final global = await marketSchedulingConfigRepository.getGlobal();
    return global.fold((f) => throw f, (c) => c);
  }
}
