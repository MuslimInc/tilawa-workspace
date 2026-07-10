import 'package:dartz_plus/dartz_plus.dart';

import '../../boundaries/dashboard/teacher_dashboard_summary_source.dart';
import '../../domain/entities/quran_session.dart';
import '../../domain/entities/teacher_availability.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/entities/market_scheduling_config.dart';
import '../../domain/entities/session_lifecycle_status.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/policies/session_list_classifier.dart';
import '../../domain/services/booked_slot_starts.dart';
import '../cache/cache_freshness_policy.dart';
import '../cache/quran_session_cache_store.dart';
import '../cache/session_cache_key.dart';
import '../../domain/repositories/market_scheduling_config_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/usecases/get_teacher_availability_usecase.dart';
import '../dashboard/teacher_dashboard_summary.dart';

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
    this.summarySource,
    this.summaryFreshness = CacheFreshnessPolicy.teacherDashboardSummaryTtl,
    this.currentTime,
  });

  final UserProfileRepository userProfileRepository;
  final MarketSchedulingConfigRepository marketSchedulingConfigRepository;
  final ScheduleRepository scheduleRepository;
  final SessionRepository sessionRepository;
  final TeacherProfileRepository teacherProfileRepository;
  final GetTeacherAvailabilityUseCase getTeacherAvailability;
  final QuranSessionCacheStore cacheStore;

  /// Server-maintained read model; `null` disables the summary-first path
  /// (feature flag off, fake wiring, tests of the legacy path).
  final TeacherDashboardSummarySource? summarySource;
  final Duration summaryFreshness;
  final DateTime Function()? currentTime;

  Future<Either<QuranSessionsFailure, TeacherDashboardResult>> call({
    required String teacherProfileId,
    required DateTime now,
    bool forceRefresh = false,
  }) async {
    final fromSummary = await _tryLoadFromSummary(teacherProfileId, now);
    if (fromSummary != null) {
      return Right(fromSummary);
    }

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

      // The profile→config chain, schedule, and upcoming sessions are
      // independent — run them concurrently instead of serial round trips.
      final profileAndConfigFuture = _loadProfileAndConfig(ownerUserId);

      final scheduleFuture = cacheStore.getOrFetch<WeeklySchedule?>(
        key: SessionCacheKey.teacherSchedule(teacherProfileId),
        ttl: CacheFreshnessPolicy.weeklyScheduleTtl,
        fetcher: () async {
          final res = await scheduleRepository.getSchedule(teacherProfileId);
          return res.fold((f) => throw f, (s) => s);
        },
      );

      final upcomingFuture = cacheStore.getOrFetch<List<QuranSession>>(
        key: SessionCacheKey.teacherDashboardSessions(teacherProfileId),
        ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
        fetcher: () async {
          final res = await sessionRepository.getTeacherUpcomingSessions(
            teacherProfileId,
          );
          return res.fold((f) => throw f, (s) => s);
        },
      );

      // Future.wait surfaces the first failure and absorbs the rest, so the
      // concurrent fetches cannot leak unhandled async errors.
      await Future.wait<Object?>([
        profileAndConfigFuture,
        scheduleFuture,
        upcomingFuture,
      ]);

      final (userProfile, schedulingConfig) = await profileAndConfigFuture;
      final schedule = await scheduleFuture;
      final allUpcoming = await upcomingFuture;

      final classified = _classifySessions(allUpcoming);
      final pendingBookingRequests = classified.pending;
      final upcomingSessions = classified.upcoming;

      final horizon = Duration(days: _horizonDays(schedulingConfig));

      final availability = await cacheStore
          .getOrFetch<List<TeacherAvailability>>(
            key: SessionCacheKey.teacherAvailability(teacherProfileId),
            ttl: CacheFreshnessPolicy.dashboardSessionsTtl,
            fetcher: () async {
              final result = await getTeacherAvailability(
                teacherProfileId,
                from: now,
                to: now.add(horizon),
                preloadedSchedule: schedule,
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

  /// Attempts the one-read summary path. Returns `null` whenever the legacy
  /// multi-fetch path must run instead: source disabled, doc missing, doc
  /// truncated, doc stale, or any fetch failure. Falling back on failure (not
  /// propagating it) keeps the projection strictly an optimization — a broken
  /// projector can never take the dashboard down.
  Future<TeacherDashboardResult?> _tryLoadFromSummary(
    String teacherProfileId,
    DateTime now,
  ) async {
    final source = summarySource;
    if (source == null) return null;

    final Either<QuranSessionsFailure, TeacherDashboardSummary?> result;
    try {
      result = await source.fetch(teacherProfileId);
    } on Object {
      return null;
    }
    final summary = result.fold((_) => null, (s) => s);
    if (summary == null || summary.sessionsTruncated) return null;

    final age = now.difference(summary.updatedAt);
    if (age > summaryFreshness) return null;

    return _resultFromSummary(summary, now);
  }

  TeacherDashboardResult _resultFromSummary(
    TeacherDashboardSummary summary,
    DateTime now,
  ) {
    final classified = _classifySessions(summary.sessions);
    final schedule = summary.weeklySchedule;

    List<TeacherAvailability> availability = const [];
    if (schedule != null && !schedule.isEmpty) {
      final horizonEnd = now.add(
        Duration(days: _horizonDays(summary.schedulingConfig)),
      );
      availability = GetTeacherAvailabilityUseCase.generateTeacherAvailability(
        schedule: schedule,
        overrides: summary.overrides,
        bookedStartsUtc: collectBookedSlotStarts(
          summary.sessions,
          windowStart: now,
          windowEnd: horizonEnd,
        ),
        windowStart: now,
        windowEnd: horizonEnd,
        now: now,
      );
    }

    return TeacherDashboardResult(
      // Projection of the owner profile — carries exactly the fields the
      // dashboard consumes (countryCode, displayName). Role/status use the
      // profile mapper's defaults.
      profile: UserProfile(
        userId: summary.ownerUserId,
        role: UserRole.student,
        accountStatus: AccountStatus.active,
        displayName: summary.displayName,
        countryCode: summary.countryCode,
      ),
      schedulingConfig: summary.schedulingConfig,
      schedule: schedule,
      pendingBookingRequests: classified.pending,
      upcomingSessions: classified.upcoming,
      availability: availability,
    );
  }

  /// Splits the raw upcoming window into pending requests vs actionable
  /// upcoming sessions — the single classification used by both the summary
  /// and legacy paths.
  ({List<QuranSession> pending, List<QuranSession> upcoming}) _classifySessions(
    List<QuranSession> allUpcoming,
  ) {
    final pending = <QuranSession>[];
    final upcoming = <QuranSession>[];
    for (final session in allUpcoming) {
      if (session.effectiveLifecycleStatus ==
          SessionLifecycleStatus.pendingTutorApproval) {
        pending.add(session);
      } else if (SessionListClassifier.isTeacherDashboardUpcoming(session)) {
        upcoming.add(session);
      }
    }
    return (pending: pending, upcoming: upcoming);
  }

  /// Dashboard availability horizon: min(config horizon, 14 days).
  int _horizonDays(MarketSchedulingConfig config) =>
      config.bookingHorizonDays < 14 ? config.bookingHorizonDays : 14;

  /// Loads the owner's user profile, then the scheduling config derived from
  /// its country code — a dependent chain that runs as one unit so it can be
  /// awaited concurrently with the schedule and sessions fetches.
  Future<(UserProfile, MarketSchedulingConfig)> _loadProfileAndConfig(
    String ownerUserId,
  ) async {
    final userProfile = await cacheStore.getOrFetch<UserProfile>(
      key: SessionCacheKey.teacherProfileByUserId(ownerUserId),
      ttl: CacheFreshnessPolicy.teacherProfileTtl,
      fetcher: () async {
        final res = await userProfileRepository.getProfile(ownerUserId);
        return res.fold((f) => throw f, (p) => p);
      },
    );
    final schedulingConfig = await _resolveSchedulingConfig(
      userProfile.countryCode,
    );
    return (userProfile, schedulingConfig);
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
