import 'package:injectable/injectable.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';

import '../entities/changelog_release.dart';
import '../entities/whats_new_eligibility.dart';
import '../repositories/whats_new_progress_repository.dart';
import 'get_current_changelog_release_use_case.dart';

/// Paths where the auto what's new prompt must not appear.
const Set<String> kWhatsNewBlockedAutoPromptPaths = <String>{
  '/splash',
  '/login',
  '/language-welcome',
  '/onboarding',
};

@lazySingleton
class GetWhatsNewEligibilityUseCase {
  GetWhatsNewEligibilityUseCase(
    this._getCurrentRelease,
    this._progressRepository,
    this._checkOnboardingStatus,
  );

  final GetCurrentChangelogReleaseUseCase _getCurrentRelease;
  final WhatsNewProgressRepository _progressRepository;
  final CheckOnboardingStatus _checkOnboardingStatus;

  Future<WhatsNewEligibility> call({
    required String currentRoutePath,
    required bool sacredFlowBlocked,
    required bool sessionAlreadyShown,
  }) async {
    if (sessionAlreadyShown) {
      return const WhatsNewEligibility.skip(WhatsNewSkipReason.sessionShown);
    }
    if (sacredFlowBlocked) {
      return const WhatsNewEligibility.skip(WhatsNewSkipReason.sacredFlow);
    }
    if (kWhatsNewBlockedAutoPromptPaths.contains(currentRoutePath)) {
      return const WhatsNewEligibility.skip(WhatsNewSkipReason.blockedRoute);
    }

    final bool onboardingCompleted = await _checkOnboardingStatus();
    if (!onboardingCompleted) {
      return const WhatsNewEligibility.skip(
        WhatsNewSkipReason.onboardingIncomplete,
      );
    }

    final releaseResult = await _getCurrentRelease();
    final ChangelogRelease? release = releaseResult.fold(
      (_) => null,
      (ChangelogRelease value) => value,
    );
    if (release == null) {
      return const WhatsNewEligibility.skip(WhatsNewSkipReason.missingRelease);
    }

    final String? lastSeen = await _progressRepository.getLastSeenReleaseId();
    if (lastSeen == release.id) {
      return const WhatsNewEligibility.skip(WhatsNewSkipReason.alreadySeen);
    }

    return WhatsNewEligibility.show(release: release);
  }
}
