import 'package:flutter/foundation.dart';

import 'session_call_control_capabilities.dart';

/// Immutable in-call control state for [QuranSessionCallControlCubit].
@immutable
class QuranSessionCallControlState {
  const QuranSessionCallControlState({
    required this.isVideoCall,
    required this.capabilities,
    this.isMicrophoneEnabled = true,
    this.isCameraEnabled = true,
    this.isSpeakerEnabled = false,
    this.isMicrophoneLoading = false,
    this.isCameraLoading = false,
    this.isSpeakerLoading = false,
    this.isSwitchCameraLoading = false,
    this.isEndCallLoading = false,
    this.hasEndedCall = false,
    this.feedback,
  });

  final bool isVideoCall;
  final SessionCallControlCapabilities capabilities;
  final bool isMicrophoneEnabled;
  final bool isCameraEnabled;
  final bool isSpeakerEnabled;
  final bool isMicrophoneLoading;
  final bool isCameraLoading;
  final bool isSpeakerLoading;
  final bool isSwitchCameraLoading;
  final bool isEndCallLoading;
  final bool hasEndedCall;
  final CallControlFeedback? feedback;

  bool get isMuted => !isMicrophoneEnabled;

  bool get canToggleMicrophone =>
      capabilities.microphone &&
      !isMicrophoneLoading &&
      !isEndCallLoading &&
      !hasEndedCall;

  bool get canToggleCamera =>
      capabilities.camera &&
      !isCameraLoading &&
      !isEndCallLoading &&
      !hasEndedCall;

  bool get canToggleSpeaker =>
      capabilities.speaker &&
      !isSpeakerLoading &&
      !isEndCallLoading &&
      !hasEndedCall;

  bool get canSwitchCamera =>
      capabilities.switchCamera &&
      !isSwitchCameraLoading &&
      !isEndCallLoading &&
      !hasEndedCall;

  bool get canEndCall => !isEndCallLoading && !hasEndedCall;

  QuranSessionCallControlState copyWith({
    bool? isMicrophoneEnabled,
    bool? isCameraEnabled,
    bool? isSpeakerEnabled,
    bool? isMicrophoneLoading,
    bool? isCameraLoading,
    bool? isSpeakerLoading,
    bool? isSwitchCameraLoading,
    bool? isEndCallLoading,
    bool? hasEndedCall,
    CallControlFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return QuranSessionCallControlState(
      isVideoCall: isVideoCall,
      capabilities: capabilities,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      isMicrophoneLoading: isMicrophoneLoading ?? this.isMicrophoneLoading,
      isCameraLoading: isCameraLoading ?? this.isCameraLoading,
      isSpeakerLoading: isSpeakerLoading ?? this.isSpeakerLoading,
      isSwitchCameraLoading:
          isSwitchCameraLoading ?? this.isSwitchCameraLoading,
      isEndCallLoading: isEndCallLoading ?? this.isEndCallLoading,
      hasEndedCall: hasEndedCall ?? this.hasEndedCall,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
    );
  }
}
