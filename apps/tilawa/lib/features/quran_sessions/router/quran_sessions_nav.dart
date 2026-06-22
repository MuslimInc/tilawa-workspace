import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../data/quran_sessions_mvp_store.dart';
import '../di/quran_sessions_backend_config.dart';

/// Routes teacher flows based on resolved [TeacherCapability].
void navigateForTeacherCapability(
  BuildContext context,
  TeacherCapability capability, {
  required QuranSessionsAnalyticsCallbacks analytics,
  bool showBlockedMessage = false,
}) {
  switch (capability.navigationTarget) {
    case TeacherCapabilityNavigationTarget.apply:
      analytics.onTeacherApplyStarted?.call();
      context.push(QuranSessionsRoutes.teacherApply);
    case TeacherCapabilityNavigationTarget.applicationStatus:
      analytics.onTeacherApplicationStatusViewed?.call();
      context.push(QuranSessionsRoutes.teacherApplicationStatus);
    case TeacherCapabilityNavigationTarget.completeTeacherProfile:
      if (showBlockedMessage) {
        TilawaFeedback.showToast(
          context,
          message: context.quranSessionsL10n.completeTeacherProfileFirstMessage,
          variant: TilawaFeedbackVariant.info,
        );
      }
      context.push(QuranSessionsRoutes.completeTeacherProfile);
    case TeacherCapabilityNavigationTarget.teacherDashboard:
      analytics.onTeacherDashboardOpened?.call();
      context.push(QuranSessionsRoutes.teacherDashboard);
  }
}

/// GoRouter route tree for the Quran Sessions feature.
List<RouteBase> get quranSessionsRoutes => [
  GoRoute(
    path: QuranSessionsRoutes.home,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: _QuranSessionsHomeRoute(
        onSeeAllTeachers: () => context.push(QuranSessionsRoutes.teacherList),
        onTeacherTapped: (id) => context.push(
          QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
        ),
        onMySessions: () => context.push(QuranSessionsRoutes.mySessions),
        onBecomeTeacher: () => _openTeacherApply(context),
        onChangeCity: () => _openProfileCompletion(context),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherList,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: TeacherListScreen(
        featureConfig: quranSessionsFeatureConfig(),
        onTeacherTapped: (id) => context.push(
          QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
        ),
        onNotifyInterest: () {},
        onChangeCity: () => _openProfileCompletion(context),
        onTeacherApplyEntry:
            quranSessionsFeatureConfig().showEmptyStateTeacherEntry
            ? () => _openTeacherApply(context)
            : null,
        onEmptyStateSeen:
            quranSessionsAnalyticsCallbacks().onQuranSessionsEmptyStateSeen,
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherProfile,
    builder: (context, state) {
      final teacherId = state.pathParameters['teacherId']!;
      final bookingEnabled =
          quranSessionsFeatureConfig().quranSessionsBookingEnabled;
      return BlocProvider(
        create: (_) {
          final now = DateTime.now();
          return getIt<TeacherProfileBloc>()..add(
            TeacherProfileRequested(
              teacherId: teacherId,
              availabilityFrom: now,
              availabilityTo: now.add(const Duration(days: 14)),
            ),
          );
        },
        child: TeacherProfileScreen(
          teacherId: teacherId,
          bookingEnabled: bookingEnabled,
          onBookTapped: bookingEnabled
              ? (tId, slotId) => context.push(
                  QuranSessionsRoutes.booking.replaceFirst(':teacherId', tId),
                  extra: slotId,
                )
              : null,
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.booking,
    redirect: (context, state) {
      if (!quranSessionsFeatureConfig().quranSessionsBookingEnabled) {
        return QuranSessionsRoutes.home;
      }
      return null;
    },
    builder: (context, state) {
      final teacherId = state.pathParameters['teacherId']!;
      final preSelectedSlotId = state.extra as String?;
      final studentId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<BookingBloc>(),
        child: BookingScreen(
          teacherId: teacherId,
          studentId: studentId,
          preSelectedSlotId: preSelectedSlotId,
          onBookingSuccess: (_) {
            context
              ..pop()
              ..pop()
              ..push(QuranSessionsRoutes.mySessions);
          },
          onCompleteProfile: () async {
            await context.push(QuranSessionsRoutes.profileCompletion);
          },
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.mySessions,
    builder: (context, state) {
      final studentId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<MySessionsBloc>(),
        child: MySessionsScreen(
          studentId: studentId,
          resolveTeacherName: _resolveTeacherName,
          onSessionDetailRequested: (bookingId) => context.push(
            QuranSessionsRoutes.sessionDetail.replaceFirst(
              ':bookingId',
              bookingId,
            ),
          ),
          onRescheduleRequested:
              ({
                required bookingId,
                required teacherId,
                required studentId,
              }) => context.push(
                QuranSessionsRoutes.rescheduleSession.replaceFirst(
                  ':bookingId',
                  bookingId,
                ),
                extra: {'teacherId': teacherId, 'actorId': studentId},
              ),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.sessionDetail,
    builder: (context, state) {
      final bookingId = state.pathParameters['bookingId']!;
      return BlocProvider(
        create: (_) => getIt<SessionDetailBloc>(),
        child: SessionDetailScreen(bookingId: bookingId),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.rescheduleSession,
    builder: (context, state) {
      final bookingId = state.pathParameters['bookingId']!;
      final extra = state.extra as Map<String, String>? ?? const {};
      return BlocProvider(
        create: (_) => getIt<RescheduleBloc>(),
        child: RescheduleSessionScreen(
          bookingId: bookingId,
          teacherId: extra['teacherId'] ?? '',
          actorId: extra['actorId'] ?? requireQuranSessionsUserId(getIt),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherDashboard,
    builder: (context, state) => _TeacherDashboardGate(
      childBuilder: (teacherId) => BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: TeacherDashboardScreen(
          teacherId: teacherId,
          onManageSchedule: () =>
              context.push(QuranSessionsRoutes.availability),
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.availability,
    builder: (context, state) => _TeacherDashboardGate(
      childBuilder: (teacherId) => BlocProvider(
        create: (_) => getIt<AvailabilityCubit>()..load(teacherId),
        child: WeeklyAvailabilityScreen(teacherId: teacherId),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.profileCompletion,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<ProfileCompletionBloc>(),
        child: ProfileCompletionScreen(userId: userId),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.completeTeacherProfile,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      return CompleteTeacherPublicProfileScreen(
        userId: userId,
        getCapability: getIt<GetCurrentUserTeacherCapabilityUseCase>(),
        saveProfile: getIt<SaveTeacherPublicProfileUseCase>(),
        onComplete: () {
          analytics.onTeacherDashboardOpened?.call();
          context
            ..pop()
            ..push(QuranSessionsRoutes.teacherDashboard);
        },
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherApply,
    redirect: (context, state) {
      if (!quranSessionsFeatureConfig().teacherApplicationEnabled) {
        return QuranSessionsRoutes.home;
      }
      return null;
    },
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      analytics.onTeacherApplyStarted?.call();
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationScreen(
          userId: userId,
          onSubmitted: () {
            analytics.onTeacherApplicationSubmitted?.call();
            context
              ..pop()
              ..push(QuranSessionsRoutes.teacherApplicationStatus);
          },
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherApplicationStatus,
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      final analytics = quranSessionsAnalyticsCallbacks();
      analytics.onTeacherApplicationStatusViewed?.call();
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationStatusScreen(
          userId: userId,
          onApproved: () async {
            analytics.onTeacherApplicationApproved?.call();
            final capabilityResult =
                await getIt<GetCurrentUserTeacherCapabilityUseCase>()(userId);
            if (!context.mounted) return;
            capabilityResult.fold(
              (_) => context.push(QuranSessionsRoutes.teacherApplicationStatus),
              (capability) {
                context.pop();
                navigateForTeacherCapability(
                  context,
                  capability,
                  analytics: analytics,
                  showBlockedMessage: capability.shouldCompleteTeacherProfile,
                );
              },
            );
          },
        ),
      );
    },
  ),
];

void _openTeacherApply(BuildContext context) {
  if (!quranSessionsFeatureConfig().teacherApplicationEnabled) {
    TilawaFeedback.showToast(
      context,
      message: context.quranSessionsL10n.teacherApplicationDisabled,
      variant: TilawaFeedbackVariant.info,
    );
    return;
  }
  quranSessionsAnalyticsCallbacks().onTeacherApplyEntrySeen?.call();
  context.push(QuranSessionsRoutes.teacherApply);
}

Future<void> _openProfileCompletion(BuildContext context) async {
  await context.push(QuranSessionsRoutes.profileCompletion);
}

String? _resolveTeacherName(String teacherId) {
  final config = getIt<AppLaunchConfig>();
  final mode = quranSessionsBackendModeFromEnvironment(
    firebaseInitEnabled: config.firebaseInit,
  );
  if (mode == QuranSessionsBackendMode.fake) {
    return QuranSessionsMvpStore.instance.resolveTeacherName(teacherId);
  }
  return null;
}

class _QuranSessionsHomeRoute extends StatefulWidget {
  const _QuranSessionsHomeRoute({
    required this.onSeeAllTeachers,
    required this.onTeacherTapped,
    required this.onMySessions,
    required this.onBecomeTeacher,
    required this.onChangeCity,
  });

  final VoidCallback onSeeAllTeachers;
  final void Function(String teacherId) onTeacherTapped;
  final VoidCallback onMySessions;
  final VoidCallback onBecomeTeacher;
  final VoidCallback onChangeCity;

  @override
  State<_QuranSessionsHomeRoute> createState() =>
      _QuranSessionsHomeRouteState();
}

class _QuranSessionsHomeRouteState extends State<_QuranSessionsHomeRoute> {
  bool _showTeacherApplyEntry = true;

  @override
  void initState() {
    super.initState();
    _loadApplyEligibility();
  }

  Future<void> _loadApplyEligibility() async {
    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) return;

    final result = await getIt<GetCurrentUserTeacherCapabilityUseCase>()(
      userId,
    );
    if (!mounted) return;

    final canApply = result.fold(
      (_) => true,
      (capability) => capability.canStartOrContinueApply,
    );
    setState(() => _showTeacherApplyEntry = canApply);
  }

  @override
  Widget build(BuildContext context) {
    return QuranSessionsHomeScreen(
      featureConfig: quranSessionsFeatureConfig(),
      analytics: quranSessionsAnalyticsCallbacks(),
      onSeeAllTeachers: widget.onSeeAllTeachers,
      onTeacherTapped: widget.onTeacherTapped,
      onMySessions: widget.onMySessions,
      onBecomeTeacher: widget.onBecomeTeacher,
      onChangeCity: widget.onChangeCity,
      showTeacherApplyEntry: _showTeacherApplyEntry,
    );
  }
}

class _TeacherDashboardGate extends StatefulWidget {
  const _TeacherDashboardGate({required this.childBuilder});

  final Widget Function(String teacherId) childBuilder;

  @override
  State<_TeacherDashboardGate> createState() => _TeacherDashboardGateState();
}

class _TeacherDashboardGateState extends State<_TeacherDashboardGate> {
  bool _allowed = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    final userId = requireQuranSessionsUserId(getIt);
    final result = await getIt<GetCurrentUserTeacherCapabilityUseCase>()(
      userId,
    );
    if (!mounted) return;

    final capability = result.fold(
      (_) => const TeacherCapability(state: TeacherCapabilityState.none),
      (value) => value,
    );

    if (capability.canAccessTeacherDashboard) {
      quranSessionsAnalyticsCallbacks().onTeacherDashboardOpened?.call();
      setState(() {
        _allowed = true;
        _checking = false;
      });
      return;
    }

    navigateForTeacherCapability(
      context,
      capability,
      analytics: quranSessionsAnalyticsCallbacks(),
      showBlockedMessage: capability.shouldCompleteTeacherProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_allowed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = requireQuranSessionsUserId(getIt);
    return widget.childBuilder(userId);
  }
}
