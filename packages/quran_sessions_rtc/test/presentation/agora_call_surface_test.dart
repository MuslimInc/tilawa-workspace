import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

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
}
