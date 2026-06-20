import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../data/quran_sessions_mvp_store.dart';

/// GoRouter route tree for the Quran Sessions MVP feature.
///
/// All routes live outside the [AppShellRoute] shell so each screen manages
/// its own [AppBar] and back navigation. The bottom navigation bar is
/// intentionally hidden — this is a dedicated feature flow.
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
          return getIt<TeacherProfileBloc>()
            ..add(
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
      return BlocProvider(
        create: (_) => getIt<BookingBloc>(),
        child: BookingScreen(
          teacherId: teacherId,
          preSelectedSlotId: preSelectedSlotId,
          onBookingSuccess: (_) {
            // Pop the booking screen, then replace the profile with My Sessions.
            context
              ..pop()
              ..pop()
              ..push(QuranSessionsRoutes.mySessions);
          },
        ),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.mySessions,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MySessionsBloc>(),
      child: MySessionsScreen(
        studentId: 'student_mvp',
        resolveTeacherName: QuranSessionsMvpStore.instance.resolveTeacherName,
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherDashboard,
    builder: (context, state) {
      // For MVP: use teacher_1 as the demo teacher. In production this comes
      // from the authenticated user's profile.
      const teacherId = 'teacher_1';
      return BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: const TeacherDashboardScreen(teacherId: teacherId),
      );
    },
  ),
];
