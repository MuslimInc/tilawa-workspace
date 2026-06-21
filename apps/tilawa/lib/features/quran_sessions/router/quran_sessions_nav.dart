import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../data/quran_sessions_mvp_store.dart';
import '../di/quran_sessions_backend_config.dart';

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
        onTeacherApplyEntry: quranSessionsFeatureConfig().showEmptyStateTeacherEntry
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
      final bookingEnabled = quranSessionsFeatureConfig().quranSessionsBookingEnabled;
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
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherDashboard,
    builder: (context, state) => _TeacherDashboardGate(
      childBuilder: (teacherId) => BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: TeacherDashboardScreen(teacherId: teacherId),
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
          onApproved: () {
            analytics.onTeacherApplicationApproved?.call();
            analytics.onTeacherDashboardOpened?.call();
            context
              ..pop()
              ..push(QuranSessionsRoutes.teacherDashboard);
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

    final result = await getIt<GetTeacherApplicationStatusUseCase>()(userId);
    if (!mounted) return;

    final canApply = result.fold(
      (_) => true,
      (application) => application.canStartOrContinueApply,
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
  @override
  void initState() {
    super.initState();
    _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    final userId = requireQuranSessionsUserId(getIt);
    final result = await getIt<GetTeacherApplicationStatusUseCase>()(userId);
    if (!mounted) return;

    final approved = result.fold(
      (_) => false,
      (application) => application.canAccessTeacherDashboard,
    );

    if (!approved) {
      context.go(QuranSessionsRoutes.teacherApplicationStatus);
      return;
    }

    quranSessionsAnalyticsCallbacks().onTeacherDashboardOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final userId = requireQuranSessionsUserId(getIt);
    return widget.childBuilder(userId);
  }
}
