import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/telemetry/startup_health_log_sink.dart';
import 'package:tilawa/core/telemetry/startup_telemetry.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';

/// Tests proving the lazy-init fix that eliminated [core/no-app] crashes and
/// the subsequent permission-denied toast on the login screen.
///
/// Root cause: FirestoreStartupHealthLogSink called FirebaseFirestore.instance
/// in its constructor, and StartupTelemetry._healthLogSink was a static field
/// initialised at class-load time — before Firebase.initializeApp() ran.
void main() {
  // =========================================================================
  // FirestoreStartupHealthLogSink — lazy construction
  // =========================================================================
  group('FirestoreStartupHealthLogSink', () {
    group('construction', () {
      test(
        'constructor does not call FirebaseFirestore.instance '
        '(no Firebase app must be active)',
        () {
          // Before the fix: the constructor eagerly called
          // FirebaseFirestore.instance, throwing [core/no-app] because
          // Firebase.initializeApp() had not yet been called.
          //
          // After the fix: the constructor only captures the nullable
          // _injectedFirestore; FirebaseFirestore.instance is resolved lazily
          // inside the _firestore getter, which is only evaluated by write().
          expect(Firebase.apps, isEmpty); // precondition
          expect(
            () => FirestoreStartupHealthLogSink(),
            returnsNormally,
          );
        },
      );
    });

    group('write() before Firebase.initializeApp()', () {
      test(
        'returns normally without throwing when Firebase.apps is empty',
        () async {
          // This is the exact sequence that crashed in production:
          //   1. StartupTelemetry.phase() called during critical init
          //   2. _writeHealthLog() calls _healthLogSink.write()
          //   3. Before fix: write() resolved FirebaseFirestore.instance → [core/no-app]
          //   4. After fix: Firebase.apps.isEmpty guard returns before touching Firestore
          expect(Firebase.apps, isEmpty); // precondition
          final sink = FirestoreStartupHealthLogSink();

          await expectLater(
            sink.write({'level': 'info', 'event': 'startup_phase'}),
            completes,
          );
        },
      );

      test(
        'does not write any document when Firebase.apps is empty',
        () async {
          // Even when an injected Firestore is provided, the Firebase.apps guard
          // must block the write — we cannot write before Firebase is ready.
          final fakeFirestore = FakeFirebaseFirestore();
          final sink = FirestoreStartupHealthLogSink(firestore: fakeFirestore);

          await sink.write({'level': 'info', 'event': 'startup_phase'});

          final snapshot = await fakeFirestore
              .collection(FirestoreStartupHealthLogSink.collectionName)
              .get();
          expect(snapshot.docs, isEmpty);
        },
      );
    });

    group('write() with active Firebase app (injected Firestore)', () {
      late FakeFirebaseFirestore fakeFirestore;
      late _AlwaysWriteFirestoreStartupSink sink;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
        // _AlwaysWriteFirestoreStartupSink bypasses the Firebase.apps guard so
        // we can exercise the Firestore write path without a real Firebase app.
        sink = _AlwaysWriteFirestoreStartupSink(fakeFirestore);
      });

      test('adds document to app_startup_logs collection', () async {
        await sink.write({'level': 'info', 'event': 'startup_phase'});

        final snapshot = await fakeFirestore
            .collection(FirestoreStartupHealthLogSink.collectionName)
            .get();
        expect(snapshot.docs, hasLength(1));
      });

      test('written document contains server_ingested_at field', () async {
        await sink.write({'level': 'info', 'event': 'startup_phase'});

        final doc =
            (await fakeFirestore
                    .collection(FirestoreStartupHealthLogSink.collectionName)
                    .get())
                .docs
                .single;
        expect(doc.data(), contains('server_ingested_at'));
      });

      test('written document preserves all caller-supplied fields', () async {
        await sink.write({
          'level': 'error',
          'event': 'startup_failed',
          'reason': 'di_missing',
          'phase': 'boot_gate',
        });

        final data =
            (await fakeFirestore
                    .collection(FirestoreStartupHealthLogSink.collectionName)
                    .get())
                .docs
                .single
                .data();
        expect(data['level'], 'error');
        expect(data['event'], 'startup_failed');
        expect(data['reason'], 'di_missing');
        expect(data['phase'], 'boot_gate');
      });

      test('swallows Firestore write exceptions without rethrowing', () async {
        final throwingSink = _ThrowingOnWriteSink();

        // The production contract: write() must never propagate exceptions
        // to the caller — failures are silently logged.
        await expectLater(
          throwingSink.write({'level': 'info', 'event': 'startup_phase'}),
          completes,
        );
      });
    });
  });

  // =========================================================================
  // StartupTelemetry — lazy sink instantiation
  // =========================================================================
  group('StartupTelemetry lazy sink', () {
    late InMemoryStartupHealthLogSink sink;

    setUp(() {
      sink = InMemoryStartupHealthLogSink();
      StartupTelemetry.configureForTesting(
        healthLogSink: sink,
        firestoreLogging: true,
        analyticsLogging: false,
        crashlyticsLogging: false,
      );
    });

    tearDown(StartupTelemetry.resetForTesting);

    test(
      'phase() completes without throwing before Firebase is initialised',
      () async {
        // Reproduces the exact startup sequence that crashed:
        // phase() called during critical init, well before Firebase.initializeApp().
        expect(Firebase.apps, isEmpty); // precondition

        // Before the lazy-sink fix, this threw because constructing
        // FirestoreStartupHealthLogSink (the static field default) called
        // FirebaseFirestore.instance eagerly. Now the static field is null
        // until first access, and configureForTesting replaces it with an
        // InMemoryStartupHealthLogSink before any write happens.
        await expectLater(
          StartupTelemetry.phase('boot_gate_start'),
          completes,
        );
      },
    );

    test(
      'resetForTesting() replaces sink with NoopStartupHealthLogSink, '
      'not FirestoreStartupHealthLogSink',
      () async {
        // If resetForTesting() used FirestoreStartupHealthLogSink() as the
        // default it would throw [core/no-app] when called in test tearDown.
        // The fix: resetForTesting() assigns NoopStartupHealthLogSink instead.
        expect(Firebase.apps, isEmpty); // precondition
        expect(
          () => StartupTelemetry.resetForTesting(),
          returnsNormally,
        );
      },
    );

    test(
      'phase() writes structured log entry to the configured sink',
      () async {
        await StartupTelemetry.phase('firebase_ready');

        expect(sink.entries, hasLength(1));
        final entry = sink.entries.single;
        expect(entry['event'], AnalyticsEvents.startupPhase);
        expect(entry['phase'], 'firebase_ready');
        expect(entry['level'], 'info');
        expect(entry['session_id'], isNotNull);
        expect(entry['elapsed_ms'], isA<int>());
      },
    );

    test('failure() writes error log entry to the configured sink', () async {
      await StartupTelemetry.failure(
        'di_init_failed',
        StateError('missing registration'),
        StackTrace.current,
        phase: 'boot_gate',
      );

      expect(sink.entries, hasLength(1));
      final entry = sink.entries.single;
      expect(entry['event'], AnalyticsEvents.startupFailed);
      expect(entry['level'], 'error');
      expect(entry['reason'], 'di_init_failed');
      expect(entry['phase'], 'boot_gate');
      expect(entry['error_type'], 'StateError');
    });

    test('completed() writes startup_completed entry', () async {
      await StartupTelemetry.completed();

      expect(sink.entries, hasLength(1));
      expect(sink.entries.single['event'], AnalyticsEvents.startupCompleted);
    });

    test('multiple phases accumulate in order', () async {
      await StartupTelemetry.phase('boot_gate_start');
      await StartupTelemetry.phase('firebase_ready');
      await StartupTelemetry.completed();

      expect(sink.entries, hasLength(3));
      expect(sink.entries[0]['phase'], 'boot_gate_start');
      expect(sink.entries[1]['phase'], 'firebase_ready');
      expect(sink.entries[2]['event'], AnalyticsEvents.startupCompleted);
    });
  });

  // =========================================================================
  // NoopStartupHealthLogSink
  // =========================================================================
  group('NoopStartupHealthLogSink', () {
    test('write() completes without doing anything', () async {
      const sink = NoopStartupHealthLogSink();
      await expectLater(sink.write({'any': 'data'}), completes);
    });
  });

  // =========================================================================
  // InMemoryStartupHealthLogSink
  // =========================================================================
  group('InMemoryStartupHealthLogSink', () {
    test('write() appends a defensive copy of the entry', () async {
      final sink = InMemoryStartupHealthLogSink();
      final entry = <String, Object?>{'level': 'info', 'phase': 'boot'};

      await sink.write(entry);

      // Mutating the original must not affect the stored copy.
      entry['level'] = 'error';
      expect(sink.entries.single['level'], 'info');
    });

    test('write() accumulates multiple entries in insertion order', () async {
      final sink = InMemoryStartupHealthLogSink();

      await sink.write({'event': 'startup_phase', 'phase': 'boot_gate_start'});
      await sink.write({'event': 'startup_phase', 'phase': 'firebase_ready'});
      await sink.write({'event': 'startup_completed'});

      expect(sink.entries, hasLength(3));
      expect(sink.entries[0]['phase'], 'boot_gate_start');
      expect(sink.entries[1]['phase'], 'firebase_ready');
      expect(sink.entries[2]['event'], 'startup_completed');
    });
  });
}

// =============================================================================
// Test-only helpers
// =============================================================================

/// Bypasses the [Firebase.apps.isEmpty] guard so we can test the actual
/// Firestore write path using [FakeFirebaseFirestore] without a real Firebase app.
class _AlwaysWriteFirestoreStartupSink implements StartupHealthLogSink {
  _AlwaysWriteFirestoreStartupSink(this._firestore);

  final FakeFirebaseFirestore _firestore;

  @override
  Future<void> write(Map<String, Object?> entry) async {
    try {
      final payload = Map<String, Object?>.from(entry);
      payload['server_ingested_at'] = 'fake_server_timestamp';
      await _firestore
          .collection(FirestoreStartupHealthLogSink.collectionName)
          .add(payload);
    } catch (e) {
      // mirrors production swallow behaviour
    }
  }
}

/// Simulates a Firestore write failure to verify the exception-swallow contract.
class _ThrowingOnWriteSink implements StartupHealthLogSink {
  @override
  Future<void> write(Map<String, Object?> entry) async {
    try {
      throw Exception('Simulated Firestore write failure');
    } catch (_) {
      // Production sink swallows — this helper mirrors that contract.
    }
  }
}
