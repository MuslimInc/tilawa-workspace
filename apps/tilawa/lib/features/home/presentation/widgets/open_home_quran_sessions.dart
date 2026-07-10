import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../quran_sessions/presentation/quran_sessions_user.dart';
import '../../../quran_sessions/quran_sessions_entry_gate.dart';
import '../../../quran_sessions/quran_sessions_feature_flags.dart';

/// Opens Learn Quran hub after Quran Sessions profile eligibility is satisfied.
Future<void> openHomeQuranSessions(BuildContext context) async {
  if (!quranSessionsFeatureConfig().showLearnQuranStudentExperience) {
    return;
  }

  final userId = _resolveUserId(context);
  if (userId == null) {
    context.push('/login');
    return;
  }

  final bool ready = await ensureQuranSessionsProfileReady(
    context,
    userId: userId,
  );
  if (!context.mounted || !ready) {
    return;
  }

  if (ready) {
    context.push(QuranSessionsRoutes.home);
  }
}

/// Resolves the current user id for Quran Sessions entry.
///
/// Prefers [AuthSessionProvider] (backed by [FirebaseAuth.currentUser]),
/// but falls back to [AuthBloc] state when the provider returns null.
/// This handles the race where [FirebaseAuth.currentUser] is transiently
/// null while the app's auth bloc is already in [AuthAuthenticated] state.
String? _resolveUserId(BuildContext context) {
  final sessionUserId = quranSessionsCurrentUserId(getIt);
  if (sessionUserId != null && sessionUserId.isNotEmpty) {
    return sessionUserId;
  }

  try {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
  } catch (_) {
    // AuthBloc not mounted — fall through to null.
  }
  return null;
}
