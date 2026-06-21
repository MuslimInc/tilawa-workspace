import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

import '../data/quran_sessions_mvp_store.dart';
import '../di/quran_sessions_backend_config.dart';
import '../presentation/quran_sessions_user.dart';

/// GoRouter route tree for the Quran Sessions feature.
List<RouteBase> get quranSessionsRoutes => [
  GoRoute(
    path: QuranSessionsRoutes.home,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: QuranSessionsHomeScreen(
        onSeeAllTeachers: () => context.push(QuranSessionsRoutes.teacherList),
        onTeacherTapped: (id) => context.push(
          QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
        ),
        onMySessions: () => context.push(QuranSessionsRoutes.mySessions),
        onBecomeTeacher: () => context.push(QuranSessionsRoutes.teacherApply),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherList,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<TeacherListBloc>()..add(const LoadTeachersRequested()),
      child: TeacherListScreen(
        onTeacherTapped: (id) => context.push(
          QuranSessionsRoutes.teacherProfile.replaceFirst(':teacherId', id),
        ),
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherProfile,
    builder: (context, state) {
      final teacherId = state.pathParameters['teacherId']!;
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
          onBookTapped: (tId, slotId) => context.push(
            QuranSessionsRoutes.booking.replaceFirst(':teacherId', tId),
            extra: slotId,
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.booking,
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
    builder: (context, state) {
      final teacherId =
          state.pathParameters['teacherId'] ??
          requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: TeacherDashboardScreen(teacherId: teacherId),
      );
    },
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
    builder: (context, state) {
      final userId = requireQuranSessionsUserId(getIt);
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationScreen(
          userId: userId,
          onSubmitted: () {
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
      return BlocProvider(
        create: (_) => getIt<TeacherApplicationBloc>(),
        child: TeacherApplicationStatusScreen(
          userId: userId,
          onApproved: () {
            context
              ..pop()
              ..push(QuranSessionsRoutes.teacherDashboard);
          },
        ),
      );
    },
  ),
];

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
