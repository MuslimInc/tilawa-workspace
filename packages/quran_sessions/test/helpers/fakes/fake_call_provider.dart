import '../../../lib/src/boundaries/call/call_provider.dart';
import '../../../lib/src/boundaries/call/call_room.dart';

/// Records calls for assertion in tests; never throws.
class FakeCallProvider implements CallProvider {
  final List<String> joinedSessions = [];
  final List<String> leftSessions = [];
  final List<String> endedSessions = [];

  @override
  Future<CallRoom> joinSession(String sessionId) async {
    joinedSessions.add(sessionId);
    return CallRoom(
      sessionId: sessionId,
      meetingUrl: 'https://fake.meeting/$sessionId',
    );
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    leftSessions.add(sessionId);
  }

  @override
  Future<void> endSession(String sessionId) async {
    endedSessions.add(sessionId);
  }
}
