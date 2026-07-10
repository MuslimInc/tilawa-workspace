import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import 'presentation/quran_sessions_user.dart';

/// Query flag when profile completion is opened from Learn Quran entry.
const String kLearnQuranProfileCompletionQuery = 'learnQuran';

/// Profile completion route scoped to Learn Quran / booking eligibility.
String learnQuranProfileCompletionLocation() {
  return '${QuranSessionsRoutes.profileCompletion}?$kLearnQuranProfileCompletionQuery=true';
}

/// Ensures Quran Sessions booking fields are complete before hub/booking entry.
///
/// Returns `true` when the student profile is complete or was just completed.
Future<bool> ensureQuranSessionsProfileReady(
  BuildContext context, {
  String? userId,
}) async {
  final String? resolvedUserId = userId ?? quranSessionsCurrentUserId(getIt);
  if (resolvedUserId == null) {
    return false;
  }

  if (!getIt.isRegistered<GetUserProfileUseCase>()) {
    return true;
  }

  final result = await getIt<GetUserProfileUseCase>()(resolvedUserId);
  if (!context.mounted) {
    return false;
  }

  final UserProfile? profile = result.fold((_) => null, (UserProfile p) => p);
  if (profile != null && profile.isComplete) {
    return true;
  }

  final bool? completed = await context.push<bool>(
    learnQuranProfileCompletionLocation(),
  );
  return completed ?? false;
}
