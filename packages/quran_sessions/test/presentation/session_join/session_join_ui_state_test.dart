import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

import 'package:quran_sessions/src/presentation/session_join/session_join_ui_state.dart';

void main() {
  final startsAt = DateTime.utc(2026, 7, 1, 12);
  const policy = SessionJoinWindowPolicy();

  test('not started before join window opens', () {
    final now = startsAt.subtract(const Duration(hours: 1));
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.confirmed,
        startsAt: startsAt,
        now: now,
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
        joinWindowPolicy: policy,
      ),
    ).equals(SessionJoinUiState.notStarted);
  });

  test('join available inside window', () {
    final now = startsAt.subtract(const Duration(minutes: 5));
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.confirmed,
        startsAt: startsAt,
        now: now,
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
        joinWindowPolicy: policy,
      ),
    ).equals(SessionJoinUiState.joinAvailable);
  });

  test('cancelled lifecycle maps to cancelled state', () {
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.cancelledByStudent,
        startsAt: startsAt,
        now: startsAt,
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
      ),
    ).equals(SessionJoinUiState.cancelled);
  });

  test('cancelled by teacher lifecycle maps to cancelled state', () {
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
        startsAt: startsAt,
        now: startsAt,
        joinInProgress: false,
        joinFailure: null,
        hasOpenedMeeting: false,
      ),
    ).equals(SessionJoinUiState.cancelled);
  });

  test('join failure surfaces failed state', () {
    final now = startsAt.subtract(const Duration(minutes: 5));
    check(
      resolveSessionJoinUiState(
        lifecycleStatus: SessionLifecycleStatus.confirmed,
        startsAt: startsAt,
        now: now,
        joinInProgress: false,
        joinFailure: const CallProviderUnavailableFailure(),
        hasOpenedMeeting: false,
        joinWindowPolicy: policy,
      ),
    ).equals(SessionJoinUiState.failed);
  });
}
