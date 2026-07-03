import 'package:flutter/scheduler.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../../../router/app_router_config.dart';

/// Query flag for profile completion routes opened right after sign-in.
const String kMandatoryProfileCompletionQuery = 'mandatory';

/// Builds the profile-completion route with [kMandatoryProfileCompletionQuery].
String mandatoryProfileCompletionLocation() {
  return '${QuranSessionsRoutes.profileCompletion}?$kMandatoryProfileCompletionQuery=true';
}

/// Resolves post-auth destination from the student's Quran Sessions profile.
Future<String> resolvePostAuthDestination(String userId) async {
  if (!getIt.isRegistered<GetUserProfileUseCase>()) {
    return const HomeRoute().location;
  }

  final result = await getIt<GetUserProfileUseCase>()(userId);
  return result.fold(
    (_) => const HomeRoute().location,
    (UserProfile profile) => profile.isComplete
        ? const HomeRoute().location
        : mandatoryProfileCompletionLocation(),
  );
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
