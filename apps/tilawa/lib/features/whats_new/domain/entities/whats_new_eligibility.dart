import 'package:equatable/equatable.dart';

import 'changelog_release.dart';

enum WhatsNewSkipReason {
  alreadySeen,
  missingRelease,
  onboardingIncomplete,
  blockedRoute,
  sacredFlow,
  sessionShown,
}

/// Result of evaluating whether the auto prompt should appear.
class WhatsNewEligibility extends Equatable {
  const WhatsNewEligibility.show({required this.release})
    : shouldShow = true,
      skipReason = null;

  const WhatsNewEligibility.skip(this.skipReason)
    : shouldShow = false,
      release = null;

  final bool shouldShow;
  final ChangelogRelease? release;
  final WhatsNewSkipReason? skipReason;

  @override
  List<Object?> get props => [shouldShow, release, skipReason];
}
