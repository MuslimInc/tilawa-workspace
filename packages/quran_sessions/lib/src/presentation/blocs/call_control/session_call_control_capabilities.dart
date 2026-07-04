import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/session_call_type.dart';

/// Which in-call controls are available for the active session.
class SessionCallControlCapabilities {
  const SessionCallControlCapabilities({
    required this.microphone,
    required this.camera,
    required this.speaker,
    required this.switchCamera,
    this.hasMultipleCameras = true,
  });

  final bool microphone;
  final bool camera;
  final bool speaker;
  final bool switchCamera;

  /// When false, the switch-camera control stays disabled (single-lens devices).
  final bool hasMultipleCameras;

  factory SessionCallControlCapabilities.forSession({
    required SessionCallProviderKind providerKind,
    required SessionCallType callType,
  }) {
    final isVideoCall = callType == SessionCallType.videoCall;
    return switch (providerKind) {
      SessionCallProviderKind.agora ||
      SessionCallProviderKind.livekit ||
      SessionCallProviderKind.mock => SessionCallControlCapabilities(
        microphone: true,
        camera: isVideoCall,
        speaker: true,
        switchCamera: isVideoCall,
        hasMultipleCameras: isVideoCall,
      ),
      SessionCallProviderKind.external => const SessionCallControlCapabilities(
        microphone: false,
        camera: false,
        speaker: false,
        switchCamera: false,
        hasMultipleCameras: false,
      ),
    };
  }
}

/// One-shot user feedback when a control action fails.
enum CallControlFeedback {
  actionFailed,
}
