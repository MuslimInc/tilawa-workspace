import 'dart:developer' as developer;

/// Staging Maestro QA teacher uid (`mu7ammadkamel@hotmail.com`).
const stagingQaTeacherUid = 'WV0m6tenTJPDLZE4EdWXBzjADF12';

/// Staging Maestro QA student uid (`mohammad.kamel@othaimmarkets.com`).
const stagingQaStudentUid = 'U33e4w08bYWFOuS7NTxoHmvDFxM2';

/// Staging-only uids that may bypass join-window timing (QA / Maestro).
const stagingQaJoinWindowBypassUids = <String>{
  stagingQaTeacherUid,
  stagingQaStudentUid,
};

const _blockedDistributions = {'production', 'play_production'};

const _stagingDistributions = {'local', 'staging'};

/// Compile-time distribution from `--dart-define=TILAWA_DISTRIBUTION=…`.
const stagingQaJoinWindowBypassDefaultDistribution = String.fromEnvironment(
  'TILAWA_DISTRIBUTION',
  defaultValue: 'local',
);

bool isStagingDistributionForQaJoinWindowBypass([
  String distribution = stagingQaJoinWindowBypassDefaultDistribution,
]) {
  if (_blockedDistributions.contains(distribution)) {
    return false;
  }
  return _stagingDistributions.contains(distribution);
}

/// Staging-only QA override: skip join-window timing for allowlisted uids.
///
/// Lifecycle, participant, and terminal-state checks stay enforced elsewhere.
bool isQaJoinWindowBypassEligible({
  required String? userId,
  String distribution = stagingQaJoinWindowBypassDefaultDistribution,
}) {
  final normalized = userId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }
  if (!stagingQaJoinWindowBypassUids.contains(normalized)) {
    return false;
  }
  if (!isStagingDistributionForQaJoinWindowBypass(distribution)) {
    return false;
  }

  developer.log(
    '[QA] join-window bypass applied for uid=$normalized',
    name: 'quran_sessions.qa_join_window',
  );
  return true;
}
