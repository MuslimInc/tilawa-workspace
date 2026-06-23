import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/cubit/session_validity_cubit.dart';
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

/// Redirects stale or unsigned users away from protected Quran Sessions routes.
///
/// Uses cached [SessionValidityCubit] state only — no Firestore read per navigation.
/// Backend callables remain the enforcement layer for mutations.
String? quranSessionsSessionRedirect(
  BuildContext context,
  GoRouterState state,
) {
  final path = state.uri.path;
  if (!isProtectedQuranSessionsPath(path)) {
    return null;
  }

  final loginLocation = const LoginRoute().location;
  if (path == loginLocation) {
    return null;
  }

  try {
    if (context.read<SessionValidityCubit>().state.revoked) {
      return loginLocation;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return loginLocation;
    }
  } catch (_) {
    // BlocProvider not mounted yet — defer to route builders.
    return null;
  }

  return null;
}
