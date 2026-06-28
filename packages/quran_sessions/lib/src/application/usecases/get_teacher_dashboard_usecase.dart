import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_session.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/entities/market_scheduling_config.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/session_list_classifier.dart';
import '../cache/cache_freshness_policy.dart';
import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';
import '../../domain/repositories/market_scheduling_config_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/get_teacher_availability_usecase.dart';

class TeacherDashboardResult {
  const TeacherDashboardResult({
    required this.profile,
    required this.schedulingConfig,
    required this.schedule,
    required this.pendingBookingRequests,
    required this.upcomingSessions,
    required this.availability,
  });

  final UserProfile profile;
  final MarketSchedulingConfig schedulingConfig;
  final WeeklySchedule? schedule;
  final List<QuranSession> pendingBookingRequests;
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
    required this.getTeacherAvailability,
    required this.cacheStore,
    this.currentTime,
  });

  final UserProfileRepository userProfileRepository;
  final MarketSchedulingConfigRepository marketSchedulingConfigRepository;
  final ScheduleRepository scheduleRepository;
  final SessionRepository sessionRepository;
  final TeacherProfileRepository teacherProfileRepository;
  final GetTeacherAvailabilityUseCase getTeacherAvailability;
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

      final allUpcoming = await cacheStore.getOrFetch<List<QuranSession>>(
        key: SessionCacheKey.teacherDashboardSessions(teacherProfileId),
        ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
        fetcher: () async {
          final res = await sessionRepository.getTeacherUpcomingSessions(
            teacherProfileId,
          );
          return res.fold((f) => throw f, (s) => s);
        },
      );

      final pendingBookingRequests = <QuranSession>[];
      final upcomingSessions = <QuranSession>[];
      for (final session in allUpcoming) {
        if (session.effectiveLifecycleStatus ==
            SessionLifecycleStatus.pendingTutorApproval) {
          pendingBookingRequests.add(session);
        } else if (SessionListClassifier.isTeacherDashboardUpcoming(session)) {
          upcomingSessions.add(session);
        }
      }

      final horizonDays = schedulingConfig.bookingHorizonDays < 14
          ? schedulingConfig.bookingHorizonDays
          : 14;
      final horizon = Duration(days: horizonDays);

      final availability = await cacheStore
          .getOrFetch<List<TeacherAvailability>>(
            key: SessionCacheKey.teacherAvailability(teacherProfileId),
            ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
            fetcher: () async {
              final result = await getTeacherAvailability(
                teacherProfileId,
                from: now,
                to: now.add(horizon),
              );
              return result.fold((f) => throw f, (slots) => slots);
            },
          );

      return Right(
        TeacherDashboardResult(
          profile: userProfile,
          schedulingConfig: schedulingConfig,
          schedule: schedule,
          pendingBookingRequests: pendingBookingRequests,
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
