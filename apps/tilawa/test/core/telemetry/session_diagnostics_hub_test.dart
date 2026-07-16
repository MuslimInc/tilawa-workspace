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
}
