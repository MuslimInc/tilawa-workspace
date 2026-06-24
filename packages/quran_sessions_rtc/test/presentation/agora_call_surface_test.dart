import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  test('buildAgoraCallSurface returns null for non-agora providers', () {
    final pool = AgoraRtcEnginePool();
    const labels = AgoraCallSurfaceLabels(
      connecting: 'Connecting',
      connected: 'Connected',
      waitingForParticipant: 'Waiting',
      voiceCallTitle: 'Call',
    );

    final surface = buildAgoraCallSurface(
      sessionId: 'session_1',
      callType: SessionCallType.videoCall,
      providerKind: SessionCallProviderKind.mock,
      enginePool: pool,
      labels: labels,
    );

    check(surface).isNull();
  });

  test('buildAgoraCallSurface returns AgoraCallSurface for agora provider', () {
    final pool = AgoraRtcEnginePool();
    const labels = AgoraCallSurfaceLabels(
      connecting: 'Connecting',
      connected: 'Connected',
      waitingForParticipant: 'Waiting',
      voiceCallTitle: 'Call',
    );

    final surface = buildAgoraCallSurface(
      sessionId: 'session_1',
      callType: SessionCallType.videoCall,
      providerKind: SessionCallProviderKind.agora,
      enginePool: pool,
      labels: labels,
    );

    check(surface).isA<AgoraCallSurface>();
  });

  group('agora call video render gates', () {
    test('remote video waits for decoding state', () {
      check(
        agoraRemoteVideoIsRenderable(RemoteVideoState.remoteVideoStateStopped),
      ).isFalse();
      check(
        agoraRemoteVideoIsRenderable(RemoteVideoState.remoteVideoStateStarting),
      ).isTrue();
      check(
        agoraRemoteVideoIsRenderable(RemoteVideoState.remoteVideoStateDecoding),
      ).isTrue();
      check(
        agoraRemoteVideoIsRenderable(RemoteVideoState.remoteVideoStateFailed),
      ).isFalse();
    });

    test('local PiP waits for capturing or encoding state', () {
      check(
        agoraLocalVideoIsRenderable(
          LocalVideoStreamState.localVideoStreamStateStopped,
        ),
      ).isFalse();
      check(
        agoraLocalVideoIsRenderable(
          LocalVideoStreamState.localVideoStreamStateCapturing,
        ),
      ).isTrue();
      check(
        agoraLocalVideoIsRenderable(
          LocalVideoStreamState.localVideoStreamStateEncoding,
        ),
      ).isTrue();
      check(
        agoraLocalVideoIsRenderable(
          LocalVideoStreamState.localVideoStreamStateFailed,
        ),
      ).isFalse();
    });
  });

  testWidgets('waiting placeholder shows message without AgoraVideoView', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: const Scaffold(
          body: AgoraCallVideoPlaceholder(
            icon: Icons.hourglass_top_outlined,
            message: 'Waiting for other party',
          ),
        ),
      ),
    );

    expect(find.text('Waiting for other party'), findsOneWidget);
    expect(find.byType(AgoraVideoView), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_outlined), findsOneWidget);
  });

  testWidgets('connecting placeholder shows spinner without AgoraVideoView', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: const Scaffold(
          body: AgoraCallVideoPlaceholder(
            icon: Icons.sync,
            message: 'Connecting',
            showSpinner: true,
          ),
        ),
      ),
    );

    expect(find.text('Connecting'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AgoraVideoView), findsNothing);
  });
}
