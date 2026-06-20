import 'call_provider.dart';
import 'call_room.dart';

/// MVP call provider — opens an external meeting link (Zoom, Google Meet, etc.)
/// supplied by the teacher when creating the session.
///
/// No SDK required. The [urlLauncher] callback lets the app inject
/// `url_launcher` without this package depending on it.
class ExternalMeetingCallProvider implements CallProvider {
  const ExternalMeetingCallProvider({
    required this.getMeetingUrl,
    required this.urlLauncher,
  });

  /// Returns the external URL for [sessionId]. Typically reads from
  /// [SessionRepository].
  final Future<String> Function(String sessionId) getMeetingUrl;

  /// Opens the URL. Inject `launchUrl` from `url_launcher`.
  final Future<void> Function(String url) urlLauncher;

  @override
  Future<CallRoom> joinSession(String sessionId) async {
    final url = await getMeetingUrl(sessionId);
    await urlLauncher(url);
    return CallRoom(sessionId: sessionId, meetingUrl: url);
  }

  @override
  Future<void> leaveSession(String sessionId) async {
    // Nothing to do — the external app manages the call lifecycle.
  }

  @override
  Future<void> endSession(String sessionId) async {
    // Nothing to do — teacher ends the call in the external app.
  }
}
