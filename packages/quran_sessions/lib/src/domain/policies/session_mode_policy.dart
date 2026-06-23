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

  String? disabledReasonCode(SessionCallType type) {
    if (isEnabled(type)) return null;
    return switch (type) {
      SessionCallType.voiceCall => 'voice_not_available',
      SessionCallType.videoCall => 'video_not_available',
      SessionCallType.externalMeeting => 'external_not_available',
    };
  }
}
