import '../../../domain/entities/session_call_provider_kind.dart';
import '../../../domain/entities/session_call_type.dart';

/// Which in-call controls are available for the active session.
class SessionCallControlCapabilities {
  const SessionCallControlCapabilities({
    required this.microphone,
    required this.camera,
    required this.speaker,
    required this.switchCamera,
  });

  final bool microphone;
  final bool camera;
  final bool speaker;
  final bool switchCamera;

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
      ),
      SessionCallProviderKind.external => const SessionCallControlCapabilities(
        microphone: false,
        camera: false,
        speaker: false,
        switchCamera: false,
      ),
    };
  }
}

/// One-shot user feedback after a control action.
enum CallControlFeedback {
  microphoneMuted,
  microphoneUnmuted,
  cameraOff,
  cameraOn,
  switchCameraBlocked,
  speakerOn,
  speakerOff,
  actionFailed,
}
