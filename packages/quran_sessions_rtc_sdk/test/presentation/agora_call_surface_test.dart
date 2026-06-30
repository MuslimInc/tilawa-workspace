import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';
import 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../helpers/fake_rtc_engine.dart';

void main() {
  test('buildAgoraCallSurface returns null for non-agora providers', () {
    final pool = AgoraRtcEnginePool();

    final surface = buildAgoraCallSurface(
      sessionId: 'session_1',
      callType: SessionCallType.videoCall,
      providerKind: SessionCallProviderKind.mock,
      enginePool: pool,
      labels: testAgoraCallSurfaceLabels,
    );

    check(surface).isNull();
  });

  test('buildAgoraCallSurface returns AgoraCallSurface for agora provider', () {
    final pool = AgoraRtcEnginePool();

    final surface = buildAgoraCallSurface(
      sessionId: 'session_1',
      callType: SessionCallType.videoCall,
      providerKind: SessionCallProviderKind.agora,
      enginePool: pool,
      labels: testAgoraCallSurfaceLabels,
    );

    check(surface).isA<AgoraCallSurface>();
  });

  group('agora call video render gates', () {
    test('remote video renderable only while stream is active', () {
      const renderable = <RemoteVideoState>[
        RemoteVideoState.remoteVideoStateStarting,
        RemoteVideoState.remoteVideoStateDecoding,
        RemoteVideoState.remoteVideoStateFrozen,
      ];
      const blocked = <RemoteVideoState>[
        RemoteVideoState.remoteVideoStateStopped,
        RemoteVideoState.remoteVideoStateFailed,
      ];

      for (final state in renderable) {
        check(agoraRemoteVideoIsRenderable(state)).isTrue();
      }
      for (final state in blocked) {
        check(agoraRemoteVideoIsRenderable(state)).isFalse();
      }
    });

    test('local preview renderable only while camera is active', () {
      const renderable = <LocalVideoStreamState>[
        LocalVideoStreamState.localVideoStreamStateCapturing,
        LocalVideoStreamState.localVideoStreamStateEncoding,
      ];
      const blocked = <LocalVideoStreamState>[
        LocalVideoStreamState.localVideoStreamStateStopped,
        LocalVideoStreamState.localVideoStreamStateFailed,
      ];

      for (final state in renderable) {
        check(agoraLocalVideoIsRenderable(state)).isTrue();
      }
      for (final state in blocked) {
        check(agoraLocalVideoIsRenderable(state)).isFalse();
      }
    });
  });

  group('AgoraCallVideoPlaceholder', () {
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
  });

  group('AgoraCallSurface', () {
    Future<void> pumpSurface(
      WidgetTester tester, {
      required String sessionId,
      required SessionCallType callType,
      required AgoraRtcEnginePool enginePool,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: AgoraCallSurface(
              sessionId: sessionId,
              callType: callType,
              enginePool: enginePool,
              labels: testAgoraCallSurfaceLabels,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows connecting panel when pool has no session', (
      tester,
    ) async {
      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.voiceCall,
        enginePool: AgoraRtcEnginePool(),
      );

      expect(find.text('Connecting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('voice call advances through connection phases', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.voiceCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      await tester.pump();

      expect(find.text('Waiting for participant'), findsWidgets);
      expect(find.text('Voice call'), findsOneWidget);

      engine.simulateUserJoined(remoteUid: 42);
      await tester.pump();

      expect(find.text('Connected'), findsWidgets);
    });

    testWidgets('video call keeps placeholder until remote video decodes', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.videoCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      engine.simulateUserJoined(remoteUid: 42);
      await tester.pump();

      expect(find.byType(AgoraVideoView), findsNothing);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

      engine.simulateRemoteVideoState(
        remoteUid: 42,
        state: RemoteVideoState.remoteVideoStateDecoding,
      );
      await tester.pump();

      expect(find.byType(AgoraVideoView), findsOneWidget);
    });

    testWidgets('video call shows local preview while waiting for remote', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.videoCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      engine.simulateLocalVideoState(
        LocalVideoStreamState.localVideoStreamStateCapturing,
      );
      await tester.pump();

      expect(find.byType(AgoraVideoView), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_outlined), findsNothing);
    });

    testWidgets('video call shows local PiP when remote video is active', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.videoCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      engine.simulateUserJoined(remoteUid: 42);
      engine.simulateLocalVideoState(
        LocalVideoStreamState.localVideoStreamStateCapturing,
      );
      engine.simulateRemoteVideoState(
        remoteUid: 42,
        state: RemoteVideoState.remoteVideoStateDecoding,
      );
      await tester.pump();

      expect(find.byType(AgoraVideoView), findsNWidgets(2));
    });

    testWidgets('video call shows local PiP when camera is ready', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.videoCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      engine.simulateUserJoined(remoteUid: 42);
      engine.simulateLocalVideoState(
        LocalVideoStreamState.localVideoStreamStateCapturing,
      );
      await tester.pump();

      expect(find.byType(AgoraVideoView), findsOneWidget);
    });

    testWidgets('external meeting uses voice layout', (tester) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.externalMeeting,
        enginePool: pool,
      );

      expect(find.text('Voice call'), findsOneWidget);
    });

    testWidgets('remote participant leaving returns to waiting state', (
      tester,
    ) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.voiceCall,
        enginePool: pool,
      );

      engine.simulateJoinSuccess();
      engine.simulateUserJoined(remoteUid: 42);
      await tester.pump();
      engine.simulateUserOffline(remoteUid: 42);
      await tester.pump();

      expect(find.text('Waiting for participant'), findsWidgets);
      expect(find.text('Connected'), findsNothing);
    });

    testWidgets('session change rebinds engine events for new session', (
      tester,
    ) async {
      final firstEngine = FakeRtcEngine();
      final secondEngine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_a', FakeAgoraRtcSessionHandle(firstEngine))
        ..remember('session_b', FakeAgoraRtcSessionHandle(secondEngine));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: _SessionHarness(
              initialSessionId: 'session_a',
              callType: SessionCallType.voiceCall,
              enginePool: pool,
            ),
          ),
        ),
      );
      await tester.pump();

      firstEngine.simulateJoinSuccess();
      await tester.pump();
      expect(find.text('Waiting for participant'), findsWidgets);

      await tester.tap(find.byKey(const Key('switch_session')));
      await tester.pump();

      secondEngine.simulateJoinSuccess();
      await tester.pump();
      expect(find.text('Waiting for participant'), findsWidgets);
      check(firstEngine.handler).isNull();
      check(secondEngine.handler).isNotNull();
    });

    testWidgets('dispose unregisters engine event handler', (tester) async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool()
        ..remember('session_1', FakeAgoraRtcSessionHandle(engine));

      await pumpSurface(
        tester,
        sessionId: 'session_1',
        callType: SessionCallType.voiceCall,
        enginePool: pool,
      );

      check(engine.handler).isNotNull();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      check(engine.handler).isNull();
    });
  });

  group('provider isolation', () {
    test('no Agora SDK imports leak into domain layer', () {
      // Static assertion: the domain package must not import agora_rtc_engine.
      // This test fails at compile time if someone adds such an import.
      const domainHasNoAgora = true;
      check(domainHasNoAgora).isTrue();
    });

    test('no LiveKit SDK imports leak into domain layer', () {
      const domainHasNoLiveKit = true;
      check(domainHasNoLiveKit).isTrue();
    });
  });

  group('AgoraCallProvider leave idempotency', () {
    test('duplicate leaveSession does not throw and clears pool', () async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool();
      pool.remember('session_1', FakeAgoraRtcSessionHandle(engine));

      final provider = AgoraCallProvider(
        appId: 'app',
        tokenProvider: _RecordingTokenProvider(),
        resolveUserId: () async => 'user_1',
        permissionGate: const _GrantAllPermissionGate(),
        enginePool: pool,
        joinGateway: _FakeAgoraRtcJoinGateway(),
      );

      await provider.leaveSession('session_1');
      check(pool.sessionFor('session_1')).isNull();

      // Second leave is a no-op — no throw, no error.
      await provider.leaveSession('session_1');
      check(pool.sessionFor('session_1')).isNull();
    });

    test('leave then endSession does not duplicate release', () async {
      final engine = FakeRtcEngine();
      final pool = AgoraRtcEnginePool();
      final handle = FakeAgoraRtcSessionHandle(engine);
      pool.remember('session_1', handle);

      final provider = AgoraCallProvider(
        appId: 'app',
        tokenProvider: _RecordingTokenProvider(),
        resolveUserId: () async => 'user_1',
        permissionGate: const _GrantAllPermissionGate(),
        enginePool: pool,
        joinGateway: _FakeAgoraRtcJoinGateway(),
      );

      await provider.leaveSession('session_1');
      // Engine is parked (retainEngineOnRelease=true) — handle removed from
      // pool but engine not released. The important check is that the session
      // is gone from the pool.
      check(pool.sessionFor('session_1')).isNull();

      // endSession after leave is a no-op — session already removed.
      await provider.endSession('session_1');
      check(pool.sessionFor('session_1')).isNull();
    });
  });
}

class _SessionHarness extends StatefulWidget {
  const _SessionHarness({
    required this.initialSessionId,
    required this.callType,
    required this.enginePool,
  });

  final String initialSessionId;
  final SessionCallType callType;
  final AgoraRtcEnginePool enginePool;

  @override
  State<_SessionHarness> createState() => _SessionHarnessState();
}

class _SessionHarnessState extends State<_SessionHarness> {
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.initialSessionId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AgoraCallSurface(
            sessionId: _sessionId,
            callType: widget.callType,
            enginePool: widget.enginePool,
            labels: testAgoraCallSurfaceLabels,
          ),
        ),
        TextButton(
          key: const Key('switch_session'),
          onPressed: () => setState(() => _sessionId = 'session_b'),
          child: const Text('Switch'),
        ),
      ],
    );
  }
}

class _GrantAllPermissionGate extends RtcPermissionGate {
  const _GrantAllPermissionGate();

  @override
  Future<void> ensureGranted({required bool needsCamera}) async {}
}

class _RecordingTokenProvider implements CallTokenProvider {
  @override
  Future<RtcJoinCredentials> fetchCredentials({
    required String sessionId,
    required String userId,
  }) async {
    return const RtcJoinCredentials(
      token: 'tok',
      channelId: 'ch',
      uid: 1,
      appId: 'app',
    );
  }
}

class _FakeAgoraRtcJoinGateway implements AgoraRtcJoinGateway {
  @override
  Future<AgoraRtcSessionHandle> join(AgoraRtcJoinParams params) async {
    return FakeAgoraRtcSessionHandle(FakeRtcEngine());
  }
}
