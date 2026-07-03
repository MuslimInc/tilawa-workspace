import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/cubit/session_validity_cubit.dart';
import '../features/quran_sessions/presentation/quran_sessions_user.dart';
import '../features/quran_sessions/quran_sessions_feature_flags.dart';
import 'app_router_config.dart';

/// Whether [path] is a Quran Sessions route that requires an active device session.
@visibleForTesting
bool isProtectedQuranSessionsPath(String path) {
  final normalized = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  return normalized == QuranSessionsRoutes.home ||
      normalized.startsWith('${QuranSessionsRoutes.home}/');
}

/// Whether [path] is a student-facing Quran Sessions route (hub, booking, …).
@visibleForTesting
bool isStudentFacingQuranSessionsPath(String path) {
  final normalized = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;

  const exactStudentPaths = <String>{
    QuranSessionsRoutes.home,
    QuranSessionsRoutes.teacherList,
    QuranSessionsRoutes.mySessions,
    QuranSessionsRoutes.wallet,
    QuranSessionsRoutes.profileCompletion,
    QuranSessionsRoutes.guardianDashboard,
    QuranSessionsRoutes.guardianApproval,
  };
  if (exactStudentPaths.contains(normalized)) {
    return true;
  }

  if (normalized.startsWith('${QuranSessionsRoutes.home}/teachers/')) {
    return true;
  }

  // Session detail and reschedule are shared by teachers (dashboard) and
  // students (my sessions). Do not gate them behind learn-quran student UX.
  return false;
}

/// Redirects when Quran Sessions feature flag is off or student experience hidden.
String? quranSessionsFeatureRedirect(GoRouterState state) {
  final path = state.uri.path;
  if (!isProtectedQuranSessionsPath(path)) {
    return null;
  }
  final config = quranSessionsFeatureConfig();
  if (!config.quranSessionsEnabled) {
    return const HomeRoute().location;
  }
  if (!config.showLearnQuranStudentExperience &&
      isStudentFacingQuranSessionsPath(path)) {
    return const HomeRoute().location;
  }
  return null;
}

/// Whether [path] requires a signed-in Quran Sessions user (bookings, detail, …).
@visibleForTesting
bool isAuthRequiredQuranSessionsPath(String path) {
  final normalized = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;

  const exactPaths = <String>{
    QuranSessionsRoutes.mySessions,
    QuranSessionsRoutes.wallet,
    QuranSessionsRoutes.teacherDashboard,
    QuranSessionsRoutes.availability,
    QuranSessionsRoutes.profileCompletion,
    QuranSessionsRoutes.completeTeacherProfile,
    QuranSessionsRoutes.guardianDashboard,
    QuranSessionsRoutes.guardianApproval,
    QuranSessionsRoutes.teacherApply,
    QuranSessionsRoutes.teacherApplicationStatus,
  };
  if (exactPaths.contains(normalized)) {
    return true;
  }

  if (normalized.startsWith('${QuranSessionsRoutes.home}/teachers/') &&
      normalized.endsWith('/book')) {
    return true;
  }

  const detailPrefix = '${QuranSessionsRoutes.home}/detail/';
  if (normalized.startsWith(detailPrefix) &&
      normalized.length > detailPrefix.length) {
    return true;
  }

  const reschedulePrefix = '${QuranSessionsRoutes.home}/reschedule/';
  if (normalized.startsWith(reschedulePrefix) &&
      normalized.length > reschedulePrefix.length) {
    return true;
  }

  return false;
}

/// Route-level redirect for Quran Sessions flows that need a signed-in user.
///
/// Used on individual GoRoutes so cold-start / notification deep links still
/// reach login when the root redirect deferred because blocs were not mounted.
String? quranSessionsAuthRequiredRedirect(
  BuildContext context,
  GoRouterState state,
) {
  if (!isAuthRequiredQuranSessionsPath(state.uri.path)) {
    return null;
  }
  return _quranSessionsLoginRedirect(
    context,
    redirectWhenAuthUnknown: true,
  );
}

/// Redirects stale or unsigned users away from protected Quran Sessions routes.
///
/// Uses cached [SessionValidityCubit] state only — no Firestore read per navigation.
/// Backend callables remain the enforcement layer for mutations.
///
/// The [SessionValidityCubit.revoked] latch is reset by a [BlocListener] on
/// [AuthBloc] at the app root when the user re-authenticates, so a freshly
/// signed-in user is not permanently locked out after a prior revocation.
String? quranSessionsSessionRedirect(
  BuildContext context,
  GoRouterState state,
) {
  final path = state.uri.path;
  if (!isProtectedQuranSessionsPath(path)) {
    return null;
  }

  final redirectWhenAuthUnknown = isAuthRequiredQuranSessionsPath(path);
  return _quranSessionsLoginRedirect(
    context,
    redirectWhenAuthUnknown: redirectWhenAuthUnknown,
  );
}

String? _quranSessionsLoginRedirect(
  BuildContext context, {
  bool redirectWhenAuthUnknown = false,
}) {
  try {
    final sessionState = context.read<SessionValidityCubit>().state;
    if (sessionState.revoked || sessionState.verificationUnknown) {
      return const LoginRoute().location;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthInitial || authState is AuthLoading) {
      logger.d(
        '[DebugNotificationAuthFlow] session guard deferred '
        '(auth restoring)',
      );
      return null;
    }
    if (authState is! AuthAuthenticated) {
      return const LoginRoute().location;
    }
  } catch (_) {
    // BlocProvider not mounted yet — fall through to AuthSessionProvider.
  }

  if (getIt.isRegistered<AuthSessionProvider>()) {
    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null || userId.isEmpty) {
      return const LoginRoute().location;
    }
    return null;
  }

  if (redirectWhenAuthUnknown) {
    return const LoginRoute().location;
  }

  return null;
}
