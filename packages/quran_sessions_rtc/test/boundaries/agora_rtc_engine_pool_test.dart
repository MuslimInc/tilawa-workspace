import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

import '../helpers/fake_rtc_engine.dart';

void main() {
  group('AgoraRtcEnginePool', () {
    late AgoraRtcEnginePool pool;

    setUp(() {
      pool = AgoraRtcEnginePool();
    });

    test('release is no-op when session is unknown', () async {
      final released = await pool.release('missing');

      check(released).isNull();
    });

    test('releaseAll clears every remembered session', () async {
      final first = FakeAgoraRtcSessionHandle(FakeRtcEngine());
      final second = FakeAgoraRtcSessionHandle(FakeRtcEngine());

      pool.remember('session_a', first);
      pool.remember('session_b', second);

      await pool.releaseAll();

      check(pool.sessionFor('session_a')).isNull();
      check(pool.sessionFor('session_b')).isNull();
      check(first.released).isTrue();
      check(second.released).isTrue();
    });

    test(
      'release parks engine and releases previous parked engine on second park',
      () async {
        final firstEngine = FakeRtcEngine();
        final secondEngine = FakeRtcEngine();
        pool.remember(
          'session_a',
          FakeAgoraRtcSessionHandle(firstEngine),
        );
        pool.remember(
          'session_b',
          FakeAgoraRtcSessionHandle(secondEngine),
        );

        await pool.release('session_a');
        await pool.release('session_b');

        check(firstEngine.released).isTrue();
        check(secondEngine.released).isFalse();
        expect(pool.takeParkedEngine(''), same(secondEngine));
      },
    );

    test('releaseAll releases parked engine retained from prior release', () async {
      final engine = FakeRtcEngine();
      pool.remember('session_a', FakeAgoraRtcSessionHandle(engine));

      await pool.release('session_a');
      check(engine.released).isFalse();

      await pool.releaseAll();

      check(engine.released).isTrue();
      check(pool.takeParkedEngine('')).isNull();
    });
  });
}
