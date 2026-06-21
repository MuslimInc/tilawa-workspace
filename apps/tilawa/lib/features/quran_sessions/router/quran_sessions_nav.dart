import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../data/quran_sessions_mvp_store.dart';

// MVP: the signed-in student is always 'student_mvp'.
const _mvpStudentId = 'student_mvp';

/// GoRouter route tree for the Quran Sessions MVP feature.
///
/// All routes live outside the [AppShellRoute] shell so each screen manages
/// its own [AppBar] and back navigation.
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
      return BlocProvider(
        create: (_) => getIt<BookingBloc>(),
        child: BookingScreen(
          teacherId: teacherId,
          studentId: _mvpStudentId,
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
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MySessionsBloc>(),
      child: MySessionsScreen(
        studentId: _mvpStudentId,
        resolveTeacherName: QuranSessionsMvpStore.instance.resolveTeacherName,
      ),
    ),
  ),
  GoRoute(
    path: QuranSessionsRoutes.teacherDashboard,
    builder: (context, state) {
      // Use path param if provided (e.g. from admin view), otherwise fall back
      // to the current MVP student who was just approved as a teacher.
      final teacherId = state.pathParameters['teacherId'] ?? _mvpStudentId;
      return BlocProvider(
        create: (_) => getIt<TeacherDashboardBloc>(),
        child: TeacherDashboardScreen(teacherId: teacherId),
      );
    },
  ),
  GoRoute(
    path: QuranSessionsRoutes.profileCompletion,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ProfileCompletionBloc>(),
      child: const ProfileCompletionScreen(userId: _mvpStudentId),
    ),
  ),

  // ── Teacher application flow ────────────────────────────────────────────────
  GoRoute(
    path: QuranSessionsRoutes.teacherApply,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TeacherApplicationBloc>(),
      child: TeacherApplicationScreen(
        userId: _mvpStudentId,
        onSubmitted: () {
          // Replace the apply screen with the status screen.
          context
            ..pop()
            ..push(QuranSessionsRoutes.teacherApplicationStatus);
        },
      ),
    ),
  ),

  GoRoute(
    path: QuranSessionsRoutes.teacherApplicationStatus,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TeacherApplicationBloc>(),
      child: TeacherApplicationStatusScreen(
        userId: _mvpStudentId,
        onApproved: () {
          // Replace the status screen with the teacher dashboard.
          context
            ..pop()
            ..push(QuranSessionsRoutes.teacherDashboard);
        },
      ),
    ),
  ),
];
