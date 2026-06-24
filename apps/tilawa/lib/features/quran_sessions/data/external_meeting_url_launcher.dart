import 'package:quran_sessions/quran_sessions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an external browser or meeting app.
///
/// Throws [ExternalMeetingLaunchFailure] when the link cannot be opened.
Future<void> launchExternalMeetingUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme.isEmpty) {
    throw const MeetingLinkUnavailableFailure();
  }

  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (opened) {
      return;
    }
  } catch (_) {
    // launchUrl failed; fall through to failure below.
  }

  throw const ExternalMeetingLaunchFailure();
}
