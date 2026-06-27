import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_ar.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations_en.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/l10n/session_lifecycle_l10n.dart';

void main() {
  group('SessionTimelinePresentationL10n', () {
    late QuranSessionsLocalizationsEn l10n;

    setUp(() {
      l10n = QuranSessionsLocalizationsEn('en');
    });

    test('never exposes tutor_cancelled raw reason in subtitle', () {
      final event = SessionAuditEvent(
        sessionId: 'session_1',
        actorId: 'teacher_1',
        actorRole: ActorRole.teacher,
        action: SessionAction.confirmBooking,
        source: ActionSource.mobileApp,
        previousStatus: SessionLifecycleStatus.scheduled,
        newStatus: SessionLifecycleStatus.scheduled,
        createdAt: DateTime.utc(2026, 6, 27),
        reason: 'tutor_cancelled',
      );

      final subtitle = event.timelineEntrySubtitle(l10n);
      check(subtitle).equals('Cancelled by the tutor');
      check(subtitle.contains('tutor_cancelled')).isFalse();
    });

    test(
      'cancellation title uses friendly copy when reason is legacy code',
      () {
        final event = SessionAuditEvent(
          sessionId: 'session_1',
          actorId: 'teacher_1',
          actorRole: ActorRole.teacher,
          action: SessionAction.confirmBooking,
          source: ActionSource.mobileApp,
          previousStatus: SessionLifecycleStatus.scheduled,
          newStatus: SessionLifecycleStatus.scheduled,
          createdAt: DateTime.utc(2026, 6, 27),
          reason: 'tutor_cancelled',
        );

        check(
          event.timelineEntryTitle(l10n),
        ).equals('Session cancelled by tutor');
      },
    );

    test('booking confirmed timeline title is localized', () {
      final event = SessionAuditEvent(
        sessionId: 'session_1',
        actorId: 'student_1',
        actorRole: ActorRole.student,
        action: SessionAction.confirmBooking,
        source: ActionSource.mobileApp,
        previousStatus: SessionLifecycleStatus.draft,
        newStatus: SessionLifecycleStatus.scheduled,
        createdAt: DateTime.utc(2026, 6, 26),
      );

      check(event.timelineEntryTitle(l10n)).equals('Booking confirmed');
    });
  });

  group('SessionStatusDisplayL10n', () {
    late QuranSessionsLocalizationsEn en;
    late QuranSessionsLocalizationsAr ar;

    setUp(() {
      en = QuranSessionsLocalizationsEn('en');
      ar = QuranSessionsLocalizationsAr('ar');
    });

    test('teacher-cancelled detail label for tutor viewer', () {
      check(
        SessionLifecycleStatus.cancelledByTeacher.sessionDetailStatusLabel(
          en,
          viewerRole: ActorRole.teacher,
        ),
      ).equals('You cancelled this session');
    });

    test('teacher-cancelled detail label for student viewer', () {
      check(
        SessionLifecycleStatus.cancelledByTeacher.sessionDetailStatusLabel(
          en,
          viewerRole: ActorRole.student,
        ),
      ).equals('Cancelled by the tutor');
    });

    test('Arabic teacher-cancelled label uses المحفظ', () {
      check(
        SessionLifecycleStatus.cancelledByTeacher.sessionDetailStatusLabel(
          ar,
          viewerRole: ActorRole.student,
        ),
      ).equals('تم إلغاء الجلسة بواسطة المحفظ');
    });
  });
}
