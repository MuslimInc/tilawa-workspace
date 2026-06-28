import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('accepted pending request maps to scheduled upcoming session', () {
    final pending = makeSession(
      lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
    );

    final scheduled = mapAcceptedBookingToScheduledSession(pending);

    check(scheduled.lifecycleStatus).equals(SessionLifecycleStatus.scheduled);
    check(scheduled.status).equals(QuranSessionStatus.scheduled);
    check(scheduled.bookingId).equals(pending.bookingId);
    check(scheduled.callProviderKind).equals(pending.callProviderKind);
  });
}
