import 'package:flutter/scheduler.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../../../router/app_router_config.dart';

/// Query flag for profile completion routes opened right after sign-in.
///
/// Deprecated: post-auth no longer routes to mandatory Quran profile completion.
/// Kept for deep-link compatibility with existing profile completion routes.
const String kMandatoryProfileCompletionQuery = 'mandatory';

/// Builds the profile-completion route with [kMandatoryProfileCompletionQuery].
String mandatoryProfileCompletionLocation() {
  return '${QuranSessionsRoutes.profileCompletion}?$kMandatoryProfileCompletionQuery=true';
}

/// Resolves post-auth destination after Google or email sign-in.
///
/// General app account creation no longer requires Quran Sessions fields.
/// Email registration writes `profileCompleted: true` at the user doc root;
/// Google sign-in sets the same when display name is present.
Future<String> resolvePostAuthDestination(String userId) async {
  return const HomeRoute().location;
}

/// Posts navigation after auth once the profile destination is known.
Future<void> schedulePostAuthNavigation({
  required bool Function() isMounted,
  required String userId,
  required void Function(String location) navigate,
}) async {
  final String destination = await resolvePostAuthDestination(userId);
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!isMounted()) {
      return;
    }
    navigate(destination);
  });
}
