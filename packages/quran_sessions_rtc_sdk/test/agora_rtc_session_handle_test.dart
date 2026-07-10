import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';

import 'helpers/fake_rtc_engine.dart';

void main() {
  group('LiveAgoraRtcSessionHandle', () {
    test('leaveAndRelease tears down native engine', () async {
      final engine = FakeRtcEngine();
      final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

      await handle.leaveAndRelease();

      check(engine.leftChannel).isTrue();
      check(engine.released).isTrue();
    });

    test('setMicrophoneMuted forwards mute to engine', () async {
      final engine = FakeRtcEngine();
      final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

      await handle.setMicrophoneMuted(true);

      check(engine.microphoneMuted).equals(true);
    });

    test(
      'setCameraEnabled disables capture and mutes publish stream',
      () async {
        final engine = FakeRtcEngine();
        final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

        await handle.setCameraEnabled(false);

        check(engine.localVideoEnabled).equals(false);
        check(engine.videoMuted).equals(true);
      },
    );

    test(
      'setCameraEnabled enables capture and unmutes publish stream',
      () async {
        final engine = FakeRtcEngine();
        final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

        await handle.setCameraEnabled(true);

        check(engine.localVideoEnabled).equals(true);
        check(engine.videoMuted).equals(false);
      },
    );

    test('exposes native engine for in-call rendering', () {
      final engine = FakeRtcEngine();
      final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

      check(identical(handle.engine, engine)).equals(true);
    });
  });
}
