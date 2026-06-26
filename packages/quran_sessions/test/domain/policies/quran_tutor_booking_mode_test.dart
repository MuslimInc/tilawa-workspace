import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('QuranTutorBookingMode', () {
    test('distribution default is autoConfirm outside play_production', () {
      check(
        distributionDefaultQuranTutorBookingMode(distribution: 'staging'),
      ).equals(QuranTutorBookingMode.autoConfirm);
    });

    test(
      'distribution default is requiresTutorApproval on play_production',
      () {
        check(
          distributionDefaultQuranTutorBookingMode(
            distribution: 'play_production',
          ),
        ).equals(QuranTutorBookingMode.requiresTutorApproval);
      },
    );

    test('tryParse reads known values', () {
      check(
        QuranTutorBookingModeParsing.tryParse('requiresTutorApproval'),
      ).equals(QuranTutorBookingMode.requiresTutorApproval);
    });
  });

  group('SessionLifecycleStatus tutor approval', () {
    test('pending blocks slot and join', () {
      const status = SessionLifecycleStatus.pendingTutorApproval;
      check(status.isSlotBlocking).isTrue();
      check(status.canJoinSession).isFalse();
    });

    test('rejected blocks join', () {
      const status = SessionLifecycleStatus.rejectedByTutor;
      check(status.canJoinSession).isFalse();
      check(status.isTerminal).isTrue();
    });
  });
}
