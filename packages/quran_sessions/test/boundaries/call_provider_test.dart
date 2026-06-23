import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/boundaries/call/external_meeting_call_provider.dart';
import '../helpers/fakes/fake_call_provider.dart';

void main() {
  group('FakeCallProvider', () {
    test('records join, leave, and end calls', () async {
      final provider = FakeCallProvider();

      await provider.joinSession('session_1');
      await provider.leaveSession('session_1');
      await provider.endSession('session_1');

      check(provider.joinedSessions).contains('session_1');
      check(provider.leftSessions).contains('session_1');
      check(provider.endedSessions).contains('session_1');
    });
  });

  group('ExternalMeetingCallProvider', () {
    test('opens URL and returns CallRoom with meetingUrl', () async {
      String? launchedUrl;
      final provider = ExternalMeetingCallProvider(
        getMeetingUrl: (_) async => 'https://meet.example.com/room',
        urlLauncher: (url) async => launchedUrl = url,
      );

      final room = await provider.joinSession('session_1');

      check(launchedUrl).equals('https://meet.example.com/room');
      check(room.meetingUrl).equals('https://meet.example.com/room');
      check(room.sessionId).equals('session_1');
    });
  });
}
