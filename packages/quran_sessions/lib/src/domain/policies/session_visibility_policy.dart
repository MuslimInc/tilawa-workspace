import '../entities/quran_session.dart';

class SessionVisibilityPolicy {
  const SessionVisibilityPolicy();

  QuranSessionTimePhase classify(QuranSession session, DateTime now) {
    return session.phaseAt(now);
  }
}
