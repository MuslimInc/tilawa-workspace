import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/islamic_widgets/app/ayah_widget_sync_service.dart';
import 'package:tilawa/features/islamic_widgets/data/daily_ayah_widget_repository.dart';
import 'package:tilawa/features/islamic_widgets/data/widget_snapshot_bridge.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/ayah_widget_payload.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/widget_snapshot_envelope.dart';

/// In-memory prefs fake covering only the members the sync service touches.
class _FakePrefs implements SharedPreferencesAsync {
  final Map<String, Object?> store = <String, Object?>{};

  @override
  Future<String?> getString(String key) async => store[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    store[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Records publish calls instead of rendering; the real repository needs the
/// QCF font pipeline, which is out of scope for the dedup-gate contract.
class _RecordingRepository implements DailyAyahWidgetRepository {
  _RecordingRepository({this.shouldThrow = false});

  final bool shouldThrow;
  final List<DateTime> publishCalls = <DateTime>[];

  @override
  Future<AyahWidgetPayload> publishFor(DateTime now) async {
    if (shouldThrow) {
      throw StateError('render failed');
    }
    publishCalls.add(now);
    return AyahWidgetPayload(
      dateKey: '2026-07-11',
      surahNumber: 2,
      ayahNumber: 152,
      pageNumber: 23,
      caption: 'سورة البقرة · ١٥٢',
      imagePathLight: '/tmp/light.png',
      imagePathDark: '/tmp/dark.png',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AyahWidgetSyncService', () {
    late _FakePrefs prefs;

    setUp(() {
      prefs = _FakePrefs();
    });

    test('publishes once per local day', () async {
      final repository = _RecordingRepository();
      final service = AyahWidgetSyncService(
        repository: repository,
        prefs: prefs,
        isSupportedOverride: true,
      );
      final DateTime morning = DateTime(2026, 7, 11, 6);
      final DateTime evening = DateTime(2026, 7, 11, 20);

      await service.syncIfNeeded(now: morning);
      await service.syncIfNeeded(now: evening);

      check(repository.publishCalls.length).equals(1);
    });

    test('publishes again on the next day', () async {
      final repository = _RecordingRepository();
      final service = AyahWidgetSyncService(
        repository: repository,
        prefs: prefs,
        isSupportedOverride: true,
      );

      await service.syncIfNeeded(now: DateTime(2026, 7, 11, 6));
      await service.syncIfNeeded(now: DateTime(2026, 7, 12, 6));

      check(repository.publishCalls.length).equals(2);
    });

    test('no-ops when unsupported', () async {
      final repository = _RecordingRepository();
      final service = AyahWidgetSyncService(
        repository: repository,
        prefs: prefs,
        isSupportedOverride: false,
      );

      await service.syncIfNeeded(now: DateTime(2026, 7, 11, 6));

      check(repository.publishCalls).isEmpty();
    });

    test('swallows publish failures and retries next call', () async {
      final failing = _RecordingRepository(shouldThrow: true);
      final service = AyahWidgetSyncService(
        repository: failing,
        prefs: prefs,
        isSupportedOverride: true,
      );

      // Must not throw.
      await service.syncIfNeeded(now: DateTime(2026, 7, 11, 6));

      // The date gate must NOT be stamped on failure — a later call retries.
      final recovering = _RecordingRepository();
      final retryService = AyahWidgetSyncService(
        repository: recovering,
        prefs: prefs,
        isSupportedOverride: true,
      );
      await retryService.syncIfNeeded(now: DateTime(2026, 7, 11, 8));
      check(recovering.publishCalls.length).equals(1);
    });
  });

  group('AyahWidgetPayload', () {
    test('serializes the native contract keys', () {
      const payload = AyahWidgetPayload(
        dateKey: '2026-07-11',
        surahNumber: 2,
        ayahNumber: 152,
        pageNumber: 23,
        caption: 'سورة البقرة · ١٥٢',
        imagePathLight: '/tmp/light.png',
        imagePathDark: '/tmp/dark.png',
      );

      final Map<String, Object?> json = payload.toJson();

      check(json['dateKey']).equals('2026-07-11');
      check(json['surahNumber']).equals(2);
      check(json['ayahNumber']).equals(152);
      check(json['pageNumber']).equals(23);
      check(json['imagePathLight']).equals('/tmp/light.png');
      check(json['imagePathDark']).equals('/tmp/dark.png');
    });
  });

  group('WidgetSnapshotBridge', () {
    test('sends generatedAtMs and validUntilMs keys (native contract)', () async {
      const channel = MethodChannel('bridge_test');
      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      const bridge = WidgetSnapshotBridge(channel);
      const payload = AyahWidgetPayload(
        dateKey: '2026-07-11',
        surahNumber: 2,
        ayahNumber: 152,
        pageNumber: 23,
        caption: 'c',
        imagePathLight: '/l.png',
        imagePathDark: '/d.png',
      );
      // ignore: prefer_const_constructors
      final envelope = WidgetSnapshotEnvelope<AyahWidgetPayload>(
        schemaVersion: 1,
        widgetType: IslamicWidgetType.ayah,
        generatedAt: DateTime(2026, 7, 11, 6),
        validUntil: DateTime(2026, 7, 12),
        payload: payload,
      );

      await bridge.dispatchSnapshot(envelope);

      check(calls.length).equals(1);
      final args = calls.single.arguments as Map<Object?, Object?>;
      final String json = args['json']! as String;
      check(json).contains('"generatedAtMs"');
      check(json).contains('"validUntilMs"');
      check(json).contains('"widgetType":"ayah"');
    });
  });
}
