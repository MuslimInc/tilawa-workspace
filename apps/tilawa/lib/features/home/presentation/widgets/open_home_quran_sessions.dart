import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../quran_sessions/presentation/quran_sessions_user.dart';
import '../../../quran_sessions/quran_sessions_entry_gate.dart';
import '../../../quran_sessions/quran_sessions_feature_flags.dart';

/// Opens Learn Quran hub after Quran Sessions profile eligibility is satisfied.
Future<void> openHomeQuranSessions(BuildContext context) async {
  if (!quranSessionsFeatureConfig().showLearnQuranStudentExperience) {
    return;
  }

  final userId = quranSessionsCurrentUserId(getIt);
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
  context.push(QuranSessionsRoutes.home);
}
