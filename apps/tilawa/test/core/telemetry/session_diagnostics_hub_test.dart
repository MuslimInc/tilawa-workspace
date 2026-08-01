import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_hub.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_snapshot.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_store.dart';

void main() {
  tearDown(() {
    SessionDiagnosticsHub.resetForTesting();
    SessionDiagnosticsStore.prefsOverride = null;
  });

  test('snapshot round-trips through JSON', () {
    const SessionDiagnosticsSnapshot snapshot = SessionDiagnosticsSnapshot(
      updatedAtIso: '2026-07-16T00:00:00.000Z',
      lifecycle: 'paused',
      route: '/player',
      playing: true,
      surahId: '2',
      ayahNumber: 255,
      reciterId: '7',
      sourceKind: 'stream',
    );

    final SessionDiagnosticsSnapshot? decoded =
        SessionDiagnosticsSnapshot.tryDecode(snapshot.encode());

    check(decoded).isNotNull();
    check(decoded!.playing).equals(true);
    check(decoded.surahId).equals('2');
    check(decoded.ayahNumber).equals(255);
    check(decoded.reciterId).equals('7');
    check(decoded.sourceKind).equals('stream');
    check(decoded.route).equals('/player');
  });

  test('enrichEvent attaches playback contexts and ANR tags', () {
    SessionDiagnosticsHub.resetForTesting();
    // Mutate via noteEvent + private path: use noteLifecycle-style public APIs.
    SessionDiagnosticsHub.noteEvent('test_play');
    SessionDiagnosticsHub.noteRoute('/home');

    final SentryEvent event = SentryEvent(
      exceptions: <SentryException>[
        SentryException(
          type: 'ApplicationNotResponding',
          value: 'ANR',
          mechanism: Mechanism(type: 'AppExitInfo'),
        ),
      ],
    );

    final SentryEvent enriched = SessionDiagnosticsHub.enrichEvent(event);

    check(SessionDiagnosticsHub.isAnrLikeEvent(enriched)).isTrue();
    check(enriched.tags?['tilawa.anr_enriched']).equals('true');
    check(
      enriched.contexts[SessionDiagnosticsHub.playbackContextKey],
    ).isNotNull();
    check(
      enriched.contexts[SessionDiagnosticsHub.sessionContextKey],
    ).isNotNull();
    check(enriched.tags?['tilawa.route']).equals('/home');
  });

  test('isAnrLikeEvent detects AppExitInfo mechanism', () {
    final SentryEvent event = SentryEvent(
      exceptions: <SentryException>[
        SentryException(
          type: 'ApplicationNotResponding',
          value: 'ANR',
          mechanism: Mechanism(type: 'AppExitInfo'),
        ),
      ],
    );
    check(SessionDiagnosticsHub.isAnrLikeEvent(event)).isTrue();
  });

  group('isNonActionableIdleBackgroundAnr', () {
    SentryEvent idleBackgroundAnr({
      String value = 'Background ANR',
      List<SentryStackFrame>? frames,
      Map<String, String>? tags,
    }) {
      return SentryEvent(
        tags: tags,
        exceptions: <SentryException>[
          SentryException(
            type: 'ApplicationNotResponding',
            value: value,
            mechanism: Mechanism(type: 'AppExitInfo'),
            stackTrace: SentryStackTrace(
              frames:
                  frames ??
                  <SentryStackFrame>[
                    SentryStackFrame(function: 'nativePollOnce'),
                    SentryStackFrame(function: 'MessageQueue.next'),
                  ],
            ),
          ),
        ],
      );
    }

    test('drops idle Background ANR when not playing', () {
      SessionDiagnosticsHub.resetForTesting();
      final SentryEvent event = idleBackgroundAnr(
        tags: <String, String>{'tilawa.playing': 'false'},
      );

      check(
        SessionDiagnosticsHub.isNonActionableIdleBackgroundAnr(event),
      ).isTrue();
    });

    test('keeps Background ANR when playback was active', () {
      SessionDiagnosticsHub.resetForTesting();
      final SentryEvent event = idleBackgroundAnr(
        tags: <String, String>{
          'tilawa.playing': 'false',
          'tilawa.prior_playing': 'true',
        },
      );

      check(
        SessionDiagnosticsHub.isNonActionableIdleBackgroundAnr(event),
      ).isFalse();
    });

    test('keeps foreground ANR even with idle frames', () {
      SessionDiagnosticsHub.resetForTesting();
      final SentryEvent event = idleBackgroundAnr(value: 'ANR');

      check(
        SessionDiagnosticsHub.isNonActionableIdleBackgroundAnr(event),
      ).isFalse();
    });

    test('keeps Background ANR without idle looper frames', () {
      SessionDiagnosticsHub.resetForTesting();
      final SentryEvent event = idleBackgroundAnr(
        frames: <SentryStackFrame>[
          SentryStackFrame(function: 'doSomethingExpensive'),
        ],
      );

      check(
        SessionDiagnosticsHub.isNonActionableIdleBackgroundAnr(event),
      ).isFalse();
    });

    test('detects idle frames via epoll_pwait on crashed main thread', () {
      SessionDiagnosticsHub.resetForTesting();
      final SentryEvent event = SentryEvent(
        exceptions: <SentryException>[
          SentryException(
            type: 'ApplicationNotResponding',
            value: 'Background ANR',
            mechanism: Mechanism(type: 'AppExitInfo'),
          ),
        ],
        threads: <SentryThread>[
          SentryThread(
            name: 'main',
            crashed: true,
            stacktrace: SentryStackTrace(
              frames: <SentryStackFrame>[
                SentryStackFrame(function: '__epoll_pwait'),
              ],
            ),
          ),
        ],
      );

      check(
        SessionDiagnosticsHub.isNonActionableIdleBackgroundAnr(event),
      ).isTrue();
    });
  });
}
