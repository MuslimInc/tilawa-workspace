import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart' show makeSession;

void main() {
  late FakeSessionRepository sessionRepo;
  late JoinSessionUseCase joinSession;
  CallJoinRequest? lastJoin;
  String? launchedUrl;
  late RoutingSessionCallProvider routingProvider;

  setUp(() {
    sessionRepo = FakeSessionRepository();
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
    );
    lastJoin = null;
  });

  test('student joins external session via routing metadata', () async {
    sessionRepo.sessions = [
      makeSession(id: 'session_1', studentId: 'student_1'),
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
        startsAt: DateTime.now().add(const Duration(hours: 1)),
        endsAt: DateTime.now().add(const Duration(hours: 2)),
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
}

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
