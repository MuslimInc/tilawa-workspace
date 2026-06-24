import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

import '../helpers/fake_rtc_engine.dart';

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

    test('exposes native engine for in-call rendering', () {
      final engine = FakeRtcEngine();
      final handle = LiveAgoraRtcSessionHandle(engine, appId: 'app_test');

      check(identical(handle.engine, engine)).equals(true);
    });
  });
}
