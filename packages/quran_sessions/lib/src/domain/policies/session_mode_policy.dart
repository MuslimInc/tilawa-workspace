import '../../domain/entities/session_call_type.dart';

/// Which session modes students may select when booking (host-configured).
///
/// Free Beta: external meeting always; voice/video use mock provider on join.
class SessionModePolicy {
  const SessionModePolicy({
    this.enabledCallTypes = const {
      SessionCallType.externalMeeting,
      SessionCallType.voiceCall,
      SessionCallType.videoCall,
    },
    this.voiceVideoUseMockProvider = true,
  });

  /// All modes enabled — mock join for voice/video during Free Beta.
  static const freeBeta = SessionModePolicy();

  /// External meeting only (teacher has no in-app RTC).
  static const externalOnly = SessionModePolicy(
    enabledCallTypes: {SessionCallType.externalMeeting},
  );

  final Set<SessionCallType> enabledCallTypes;

  /// When true, voice/video bookings are allowed but join uses mock provider.
  final bool voiceVideoUseMockProvider;

  bool isEnabled(SessionCallType type) => enabledCallTypes.contains(type);

  /// True when [url] is a non-empty external meeting link.
  static bool hasExternalMeetingUrl(String? url) =>
      url != null && url.trim().isNotEmpty;

  /// Disables external meeting when the teacher has no meeting URL.
  SessionModePolicy withoutExternalMeeting() {
    final next = Set<SessionCallType>.from(enabledCallTypes)
      ..remove(SessionCallType.externalMeeting);
    return SessionModePolicy(
      enabledCallTypes: next,
      voiceVideoUseMockProvider: voiceVideoUseMockProvider,
    );
  }

  /// Host policy adjusted for whether the teacher configured a meeting URL.
  SessionModePolicy forTeacherExternalMeetingUrl(String? url) =>
      hasExternalMeetingUrl(url) ? this : withoutExternalMeeting();

  /// Default booking call type for [policy] and teacher meeting URL.
  static SessionCallType defaultCallType({
    required SessionModePolicy policy,
    required String? externalMeetingUrl,
  }) {
    final effective = policy.forTeacherExternalMeetingUrl(externalMeetingUrl);
    if (effective.isEnabled(SessionCallType.externalMeeting)) {
      return SessionCallType.externalMeeting;
    }
    if (effective.isEnabled(SessionCallType.voiceCall)) {
      return SessionCallType.voiceCall;
    }
    if (effective.isEnabled(SessionCallType.videoCall)) {
      return SessionCallType.videoCall;
    }
    return SessionCallType.externalMeeting;
  }

  String? disabledReasonCode(SessionCallType type) {
    if (isEnabled(type)) return null;
    return switch (type) {
      SessionCallType.voiceCall => 'voice_not_available',
      SessionCallType.videoCall => 'video_not_available',
      SessionCallType.externalMeeting => 'external_not_available',
    };
  }
}
