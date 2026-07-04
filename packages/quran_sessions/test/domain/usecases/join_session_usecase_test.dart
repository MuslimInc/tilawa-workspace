import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart' show makeSession, makeTeacherProfile;

/// Start time inside the Q-VC-03 join window (15m lead) so joins are allowed.
DateTime withinJoinWindowStart() =>
    DateTime.now().toUtc().add(const Duration(minutes: 10));

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeTeacherProfileRepository teacherProfiles;
  late JoinSessionUseCase joinSession;
  CallJoinRequest? lastJoin;
  String? launchedUrl;
  late RoutingSessionCallProvider routingProvider;

  setUp(() {
    sessionRepo = FakeSessionRepository();
    teacherProfiles = FakeTeacherProfileRepository();
    lastJoin = null;
    launchedUrl = null;
    routingProvider = RoutingSessionCallProvider(
      external: ExternalMeetingCallProvider(
        getMeetingUrl: (_) async => 'https://meet.example.com/r',
        urlLauncher: (url) async => launchedUrl = url,
      ),
      mock: MockSessionCallProvider(onJoin: (request) => lastJoin = request),
    );
    joinSession = JoinSessionUseCase(
      sessionRepository: sessionRepo,
      callProvider: routingProvider,
      authSession: _FakeAuthSession('student_1'),
      teacherProfileRepository: teacherProfiles,
    );
    lastJoin = null;
  });

  test('student joins external session via routing metadata', () async {
    sessionRepo.sessions = [
      makeSession(
        id: 'session_1',
        studentId: 'student_1',
        startsAt: withinJoinWindowStart(),
      ),
    ];

    final result = await joinSession(sessionId: 'session_1');

    check(result.isRight()).isTrue();
    check(launchedUrl).equals('https://meet.example.com/room');
  });

  test('voice session uses mock provider channel from server', () async {
    sessionRepo.sessions = [
      QuranSession(
        id: 'session_voice',
        bookingId: 'booking_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        startsAt: withinJoinWindowStart(),
        endsAt: withinJoinWindowStart().add(const Duration(hours: 1)),
        callType: SessionCallType.voiceCall,
        status: QuranSessionStatus.scheduled,
        callProviderKind: SessionCallProviderKind.mock,
        providerSessionId: 'session_voice',
      ),
    ];

    final result = await joinSession(sessionId: 'session_voice');

    check(result.isRight()).isTrue();
    check(lastJoin?.callType).equals(SessionCallType.voiceCall);
    check(lastJoin?.providerKind).equals(SessionCallProviderKind.mock);
    check(lastJoin?.providerSessionId).equals('session_voice');
  });

  test('rejects join when lifecycle does not allow', () async {
    sessionRepo.sessions = [
      makeSession(
        id: 'session_done',
        studentId: 'student_1',
        status: QuranSessionStatus.completed,
      ),
    ];

    final result = await joinSession(sessionId: 'session_done');

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<InvalidTransitionFailure>(),
      (_) => fail('expected Left'),
    );
  });

  test('rejects join when caller is not a participant', () async {
    sessionRepo.sessions = [
      makeSession(id: 'session_1', studentId: 'other_student'),
    ];

    final result = await joinSession(sessionId: 'session_1');

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<UnauthorizedFailure>(),
      (_) => fail('expected Left'),
    );
  });

  test('teacher joins with teacher role metadata', () async {
    sessionRepo.sessions = [
      makeSession(
        id: 'session_1',
        studentId: 'student_1',
        startsAt: withinJoinWindowStart(),
      ),
    ];
    joinSession = JoinSessionUseCase(
      sessionRepository: sessionRepo,
      callProvider: routingProvider,
      authSession: _FakeAuthSession('teacher_1'),
      teacherProfileRepository: teacherProfiles,
    );

    final result = await joinSession(sessionId: 'session_1');

    check(result.isRight()).isTrue();
    check(launchedUrl).equals('https://meet.example.com/room');
  });

  test(
    'teacher joins when session teacherId is profile doc not auth uid',
    () async {
      const profileDocId = 'profile_doc_abc';
      const authUid = 'firebase_uid_teacher';
      teacherProfiles.seed(
        makeTeacherProfile(id: profileDocId, userId: authUid),
      );
      final startsAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
      sessionRepo.sessions = [
        makeSession(
          id: 'session_1',
          studentId: 'student_1',
          teacherId: profileDocId,
          startsAt: startsAt,
          endsAt: startsAt.add(const Duration(hours: 1)),
        ),
      ];
      joinSession = JoinSessionUseCase(
        sessionRepository: sessionRepo,
        callProvider: routingProvider,
        authSession: _FakeAuthSession(authUid),
        teacherProfileRepository: teacherProfiles,
      );

      final result = await joinSession(sessionId: 'session_1');

      check(result.isRight()).isTrue();
      check(launchedUrl).equals('https://meet.example.com/room');
    },
  );

  test('external join fails when meeting link missing', () async {
    sessionRepo.sessions = [
      QuranSession(
        id: 'session_no_link',
        bookingId: 'booking_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        startsAt: withinJoinWindowStart(),
        endsAt: withinJoinWindowStart().add(const Duration(hours: 1)),
        callType: SessionCallType.externalMeeting,
        status: QuranSessionStatus.scheduled,
        callProviderKind: SessionCallProviderKind.external,
      ),
    ];
    routingProvider = RoutingSessionCallProvider(
      external: ExternalMeetingCallProvider(
        getMeetingUrl: (_) async => '',
        urlLauncher: (url) async => launchedUrl = url,
      ),
      mock: MockSessionCallProvider(onJoin: (request) => lastJoin = request),
    );
    joinSession = JoinSessionUseCase(
      sessionRepository: sessionRepo,
      callProvider: routingProvider,
      authSession: _FakeAuthSession('student_1'),
      teacherProfileRepository: teacherProfiles,
    );

    final result = await joinSession(sessionId: 'session_no_link');

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<MeetingLinkUnavailableFailure>(),
      (_) => fail('expected Left'),
    );
  });

  test('records join telemetry without blocking join', () async {
    final recordingGateway = InMemoryCallTelemetryGateway();
    final hub = SessionCallProviderEventHub();
    final telemetry = QuranSessionCallTelemetryCoordinator(
      gateway: recordingGateway,
      eventHub: hub,
    );
    routingProvider = RoutingSessionCallProvider(
      external: ExternalMeetingCallProvider(
        getMeetingUrl: (_) async => 'https://meet.example.com/r',
        urlLauncher: (url) async => launchedUrl = url,
      ),
      mock: MockSessionCallProvider(
        onJoin: (request) => lastJoin = request,
        eventHub: hub,
      ),
    );
    joinSession = JoinSessionUseCase(
      sessionRepository: sessionRepo,
      callProvider: routingProvider,
      authSession: _FakeAuthSession('student_1'),
      teacherProfileRepository: teacherProfiles,
      callTelemetry: telemetry,
    );
    sessionRepo.sessions = [
      QuranSession(
        id: 'session_voice',
        bookingId: 'booking_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        startsAt: withinJoinWindowStart(),
        endsAt: withinJoinWindowStart().add(const Duration(hours: 1)),
        callType: SessionCallType.voiceCall,
        status: QuranSessionStatus.scheduled,
        callProviderKind: SessionCallProviderKind.mock,
        providerSessionId: 'session_voice',
      ),
    ];

    final result = await joinSession(sessionId: 'session_voice');
    await pumpEventQueue();

    check(result.isRight()).isTrue();
    check(
      recordingGateway.recorded.map((event) => event.type).toSet(),
    ).deepEquals({
      QuranSessionCallTelemetryEventType.joinRequested,
      QuranSessionCallTelemetryEventType.joinSucceeded,
      QuranSessionCallTelemetryEventType.participantConnected,
    });
    telemetry.dispose();
    hub.dispose();
  });
}

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
