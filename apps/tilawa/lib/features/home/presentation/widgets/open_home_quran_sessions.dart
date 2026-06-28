import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../quran_sessions/presentation/quran_sessions_user.dart';
import '../../../quran_sessions/quran_sessions_feature_flags.dart';

/// Opens Quran Sessions when the profile is complete, otherwise gates first.
Future<void> openHomeQuranSessions(BuildContext context) async {
  if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
    return;
  }

  final userId = quranSessionsCurrentUserId(getIt);
  if (userId == null) {
    context.push('/login');
    return;
  }

  final result = await getIt<GetUserProfileUseCase>()(userId);
  if (!context.mounted) return;

  final profile = result.fold((_) => null, (p) => p);
  if (profile != null && profile.isComplete) {
    context.push(QuranSessionsRoutes.home);
    return;
  }

  final completed = await context.push<bool>(
    QuranSessionsRoutes.profileCompletion,
  );
  if (!context.mounted) return;
  if (completed == true) {
    context.push(QuranSessionsRoutes.home);
  }
}
