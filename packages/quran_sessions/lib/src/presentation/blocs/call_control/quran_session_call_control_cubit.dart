import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/call/session_call_control_gateway.dart';
import 'quran_session_call_control_state.dart';
import 'session_call_control_capabilities.dart';

/// Drives in-call media controls for [InAppCallShellScreen].
class QuranSessionCallControlCubit extends Cubit<QuranSessionCallControlState> {
  QuranSessionCallControlCubit({
    required this._gateway,
    required bool isVideoCall,
    required SessionCallControlCapabilities capabilities,
  }) : super(
         QuranSessionCallControlState(
           isVideoCall: isVideoCall,
           capabilities: capabilities,
         ),
       );

  final SessionCallControlGateway _gateway;

  void clearFeedback() {
    if (state.feedback == null) {
      return;
    }
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> toggleMicrophone() async {
    if (!state.canToggleMicrophone) {
      return;
    }

    final nextEnabled = !state.isMicrophoneEnabled;
    emit(
      state.copyWith(
        isMicrophoneLoading: true,
        clearFeedback: true,
      ),
    );

    try {
      await _gateway.setMicrophoneEnabled(enabled: nextEnabled);
      emit(
        state.copyWith(
          isMicrophoneEnabled: nextEnabled,
          isMicrophoneLoading: false,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isMicrophoneLoading: false,
          feedback: CallControlFeedback.actionFailed,
        ),
      );
    }
  }

  Future<void> toggleCamera() async {
    if (!state.canToggleCamera) {
      return;
    }

    final nextEnabled = !state.isCameraEnabled;
    emit(
      state.copyWith(
        isCameraLoading: true,
        clearFeedback: true,
      ),
    );

    try {
      await _gateway.setCameraEnabled(enabled: nextEnabled);
      emit(
        state.copyWith(
          isCameraEnabled: nextEnabled,
          isCameraLoading: false,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isCameraLoading: false,
          feedback: CallControlFeedback.actionFailed,
        ),
      );
    }
  }

  Future<void> toggleSpeaker() async {
    if (!state.canToggleSpeaker) {
      return;
    }

    final nextEnabled = !state.isSpeakerEnabled;
    emit(
      state.copyWith(
        isSpeakerLoading: true,
        clearFeedback: true,
      ),
    );

    try {
      await _gateway.setSpeakerEnabled(enabled: nextEnabled);
      emit(
        state.copyWith(
          isSpeakerEnabled: nextEnabled,
          isSpeakerLoading: false,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isSpeakerLoading: false,
          feedback: CallControlFeedback.actionFailed,
        ),
      );
    }
  }

  Future<void> switchCamera() async {
    if (!state.canSwitchCamera) {
      return;
    }

    emit(
      state.copyWith(
        isSwitchCameraLoading: true,
        clearFeedback: true,
      ),
    );

    try {
      await _gateway.switchCamera();
      emit(
        state.copyWith(
          isSwitchCameraLoading: false,
          cameraFacing: state.cameraFacing.opposite,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isSwitchCameraLoading: false,
          feedback: CallControlFeedback.actionFailed,
        ),
      );
    }
  }

  Future<void> endCall() async {
    if (!state.canEndCall) {
      return;
    }

    emit(
      state.copyWith(
        isEndCallLoading: true,
        hasEndedCall: true,
        clearFeedback: true,
      ),
    );

    try {
      await _gateway.leave();
      emit(state.copyWith(isEndCallLoading: false));
    } on Object {
      emit(
        state.copyWith(
          isEndCallLoading: false,
          hasEndedCall: false,
          feedback: CallControlFeedback.actionFailed,
        ),
      );
    }
  }
}
