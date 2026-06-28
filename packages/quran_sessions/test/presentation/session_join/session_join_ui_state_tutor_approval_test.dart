import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/session_join/session_join_ui_state.dart';

void main() {
  final startsAt = DateTime.utc(2026, 6, 26, 14);

  test('pending tutor approval maps to awaitingTutorApproval', () {
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        startsAt: startsAt,
        now: startsAt.subtract(const Duration(hours: 1)),
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
      ),
    ).equals(SessionJoinUiState.awaitingTutorApproval);
  });

  test('rejected by tutor maps to rejectedByTutor', () {
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.rejectedByTutor,
        startsAt: startsAt,
        now: startsAt.subtract(const Duration(hours: 1)),
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
      ),
    ).equals(SessionJoinUiState.rejectedByTutor);
  });
}
