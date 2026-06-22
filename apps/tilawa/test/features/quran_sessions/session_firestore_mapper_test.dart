import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'package:tilawa/features/quran_sessions/data/firebase/session_firestore_mapper.dart';

void main() {
  test('parseLifecycleStatus reads snake_case Firestore values', () {
    check(
      parseLifecycleStatus('pending_payment'),
    ).equals(SessionLifecycleStatus.pendingPayment);
    check(
      parseLifecycleStatus('teacher_no_show'),
    ).equals(SessionLifecycleStatus.teacherNoShow);
    check(
      parseLifecycleStatus('cancelled_by_student'),
    ).equals(SessionLifecycleStatus.cancelledByStudent);
  });
}
