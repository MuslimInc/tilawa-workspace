import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('QuranSessionCallControlCubit', () {
    late _FakeCallControlGateway gateway;
    late SessionCallControlCapabilities capabilities;

    QuranSessionCallControlCubit buildCubit({bool isVideoCall = false}) {
      return QuranSessionCallControlCubit(
        gateway: gateway,
        isVideoCall: isVideoCall,
        capabilities: capabilities,
      );
    }

    setUp(() {
      gateway = _FakeCallControlGateway();
      capabilities = const SessionCallControlCapabilities(
        microphone: true,
        camera: true,
        speaker: true,
        switchCamera: true,
      );
    });

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'toggleMicrophone mutes then unmutes via gateway',
      build: buildCubit,
      act: (cubit) async {
        await cubit.toggleMicrophone();
        await cubit.toggleMicrophone();
      },
      expect: () => [
        isA<QuranSessionCallControlState>().having(
          (s) => s.isMicrophoneLoading,
          'loading',
          isTrue,
        ),
        isA<QuranSessionCallControlState>().having(
          (s) => s.isMuted,
          'muted',
          isTrue,
        ),
        isA<QuranSessionCallControlState>().having(
          (s) => s.isMicrophoneLoading,
          'loading',
          isTrue,
        ),
        isA<QuranSessionCallControlState>().having(
          (s) => s.isMicrophoneEnabled,
          'enabled',
          isTrue,
        ),
      ],
      verify: (_) {
        check(gateway.microphoneEnabledCalls).deepEquals([false, true]);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'toggleCamera disables then enables camera',
      build: buildCubit,
      act: (cubit) async {
        await cubit.toggleCamera();
        await cubit.toggleCamera();
      },
      verify: (_) {
        check(gateway.cameraEnabledCalls).deepEquals([false, true]);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'toggleSpeaker enables speaker route',
      build: buildCubit,
      act: (cubit) async => cubit.toggleSpeaker(),
      verify: (_) {
        check(gateway.speakerEnabledCalls).deepEquals([true]);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'switchCamera no-ops when camera disabled',
      build: buildCubit,
      seed: () => QuranSessionCallControlState(
        isVideoCall: true,
        capabilities: capabilities,
        isCameraEnabled: false,
      ),
      act: (cubit) async => cubit.switchCamera(),
      expect: () => <QuranSessionCallControlState>[],
      verify: (_) {
        check(gateway.switchCameraCount).equals(0);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'switchCamera forwards to gateway when camera on',
      build: buildCubit,
      act: (cubit) async => cubit.switchCamera(),
      expect: () => [
        isA<QuranSessionCallControlState>().having(
          (s) => s.isSwitchCameraLoading,
          'loading',
          isTrue,
        ),
        isA<QuranSessionCallControlState>()
            .having(
              (s) => s.cameraFacing,
              'facing',
              SessionCallCameraFacing.back,
            )
            .having((s) => s.isSwitchCameraLoading, 'loading', isFalse),
      ],
      verify: (_) {
        check(gateway.switchCameraCount).equals(1);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'switchCamera blocked when device has one camera',
      build: () {
        return QuranSessionCallControlCubit(
          gateway: gateway,
          isVideoCall: true,
          capabilities: const SessionCallControlCapabilities(
            microphone: true,
            camera: true,
            speaker: true,
            switchCamera: true,
            hasMultipleCameras: false,
          ),
        );
      },
      act: (cubit) async => cubit.switchCamera(),
      verify: (_) {
        check(gateway.switchCameraCount).equals(0);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'endCall deduplicates while in flight',
      build: buildCubit,
      act: (cubit) async {
        final first = cubit.endCall();
        final second = cubit.endCall();
        await Future.wait([first, second]);
      },
      verify: (_) {
        check(gateway.leaveCount).equals(1);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'provider failure surfaces actionFailed feedback',
      build: () {
        gateway.shouldFail = true;
        return buildCubit();
      },
      act: (cubit) async => cubit.toggleMicrophone(),
      expect: () => [
        isA<QuranSessionCallControlState>().having(
          (s) => s.isMicrophoneLoading,
          'loading',
          isTrue,
        ),
        isA<QuranSessionCallControlState>()
            .having((s) => s.isMuted, 'muted', isFalse)
            .having(
              (s) => s.feedback,
              'feedback',
              CallControlFeedback.actionFailed,
            ),
      ],
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'switchCamera failure surfaces actionFailed feedback',
      build: () {
        gateway.shouldFailSwitchCamera = true;
        return buildCubit(isVideoCall: true);
      },
      act: (cubit) async => cubit.switchCamera(),
      expect: () => [
        isA<QuranSessionCallControlState>().having(
          (s) => s.isSwitchCameraLoading,
          'loading',
          isTrue,
        ),
        isA<QuranSessionCallControlState>()
            .having(
              (s) => s.cameraFacing,
              'facing',
              SessionCallCameraFacing.front,
            )
            .having(
              (s) => s.feedback,
              'feedback',
              CallControlFeedback.actionFailed,
            ),
      ],
      verify: (_) {
        check(gateway.switchCameraCount).equals(1);
      },
    );

    blocTest<QuranSessionCallControlCubit, QuranSessionCallControlState>(
      'endCall failure clears hasEndedCall guard',
      build: () {
        gateway.shouldFailOnLeave = true;
        return buildCubit();
      },
      act: (cubit) async => cubit.endCall(),
      expect: () => [
        isA<QuranSessionCallControlState>()
            .having((s) => s.isEndCallLoading, 'loading', isTrue)
            .having((s) => s.hasEndedCall, 'ended', isTrue),
        isA<QuranSessionCallControlState>()
            .having((s) => s.hasEndedCall, 'ended', isFalse)
            .having(
              (s) => s.feedback,
              'feedback',
              CallControlFeedback.actionFailed,
            ),
      ],
    );
  });
}

class _FakeCallControlGateway implements SessionCallControlGateway {
  final List<bool> microphoneEnabledCalls = [];
  final List<bool> cameraEnabledCalls = [];
  final List<bool> speakerEnabledCalls = [];
  int switchCameraCount = 0;
  int leaveCount = 0;
  bool shouldFail = false;
  bool shouldFailOnLeave = false;
  bool shouldFailSwitchCamera = false;

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {
    if (shouldFail) {
      throw StateError('microphone failed');
    }
    microphoneEnabledCalls.add(enabled);
  }

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {
    cameraEnabledCalls.add(enabled);
  }

  @override
  Future<void> switchCamera() async {
    switchCameraCount++;
    if (shouldFailSwitchCamera) {
      throw StateError('switch camera failed');
    }
  }

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {
    speakerEnabledCalls.add(enabled);
  }

  @override
  Future<void> leave() async {
    if (shouldFailOnLeave) {
      throw StateError('leave failed');
    }
    leaveCount++;
  }
}
