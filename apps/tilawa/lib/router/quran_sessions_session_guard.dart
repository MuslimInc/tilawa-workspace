import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/cubit/session_validity_cubit.dart';
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

/// Redirects when Quran Sessions feature flag is off.
String? quranSessionsFeatureRedirect(GoRouterState state) {
  final path = state.uri.path;
  if (!isProtectedQuranSessionsPath(path)) {
    return null;
  }
  if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
    return const HomeRoute().location;
  }
  return null;
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

  try {
    if (context.read<SessionValidityCubit>().state.revoked) {
      return const LoginRoute().location;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const LoginRoute().location;
    }
  } catch (_) {
    // BlocProvider not mounted yet — defer to route builders.
    return null;
  }

  return null;
}
