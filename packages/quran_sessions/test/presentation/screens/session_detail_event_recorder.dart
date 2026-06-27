import 'package:quran_sessions/quran_sessions.dart';

/// Captures [SessionDetailEvent]s from widget tests without public bloc APIs.
class SessionDetailEventRecorder {
  final List<SessionDetailEvent> events = [];

  void record(SessionDetailEvent event) => events.add(event);

  void clear() => events.clear();
}
