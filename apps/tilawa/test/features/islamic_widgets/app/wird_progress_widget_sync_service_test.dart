import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/islamic_widgets/app/wird_progress_widget_sync_service.dart';
import 'package:tilawa/features/islamic_widgets/data/widget_snapshot_bridge.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/widget_snapshot_envelope.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart';
import 'package:tilawa/features/islamic_widgets/presentation/adapters/wird_progress_widget_adapter.dart';
import 'package:tilawa/features/smart_khatma/domain/entities/khatma_plan.dart';
import 'package:tilawa/features/smart_khatma/domain/repositories/khatma_plan_repository.dart';
import 'package:tilawa/features/smart_khatma/domain/usecases/get_wird_progress_summary_use_case.dart';
import 'package:tilawa_core/config/language_config.dart';

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Captures dispatched envelopes instead of crossing the method channel.
class _CapturingBridge extends WidgetSnapshotBridge {
  _CapturingBridge() : super(const MethodChannel('wird_sync_test'));

  final List<WidgetSnapshotEnvelope<Object>> envelopes =
      <WidgetSnapshotEnvelope<Object>>[];

  @override
  Future<void> dispatchSnapshot<T extends Object>(
    WidgetSnapshotEnvelope<T> envelope,
  ) async {
    envelopes.add(envelope);
  }
}

/// Serves a single plan (or an error) for `getActivePlan`.
class _FakeKhatmaPlanRepository implements KhatmaPlanRepository {
  KhatmaPlan? plan;
  bool throwOnRead = false;

  @override
  Future<KhatmaPlan?> getActivePlan() async {
    if (throwOnRead) {
      throw Exception('plan store unreadable');
    }
    return plan;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final DateTime today = DateTime(2026, 7, 12, 9, 30);

  KhatmaPlan activePlan({int currentPage = 1, bool withProgress = false}) {
    return KhatmaPlan(
      id: 'plan-1',
      createdAt: DateTime(2026, 7, 12),
      startDate: DateTime(2026, 7, 12),
      durationDays: 30,
      startPage: 1,
      targetPage: 604,
      assignmentDate: DateTime(2026, 7, 12),
      assignmentStartPage: 1,
      assignmentEndPage: 6,
    );
  }

  late _FakePrefs prefs;
  late _CapturingBridge bridge;
  late _FakeKhatmaPlanRepository repository;

  setUp(() {
    prefs = _FakePrefs();
    bridge = _CapturingBridge();
    repository = _FakeKhatmaPlanRepository();
  });

  WirdProgressWidgetSyncService service({bool isSupported = true}) {
    return WirdProgressWidgetSyncService(
      useCase: GetWirdProgressSummaryUseCase(repository),
      bridge: bridge,
      prefs: prefs,
      adapter: WirdProgressWidgetAdapter(now: () => today),
      isSupportedOverride: isSupported,
    );
  }

  WirdProgressWidgetPayload payloadOf(int index) =>
      bridge.envelopes[index].payload as WirdProgressWidgetPayload;

  group('WirdProgressWidgetSyncService', () {
    test('no-ops when the platform is unsupported', () async {
      await service(isSupported: false).syncIfNeeded(now: today);

      check(bridge.envelopes).isEmpty();
    });

    test('dispatches a wird snapshot for the no-plan CTA state', () async {
      prefs.store[LanguageConfig.languageKey] = 'en';
      repository.plan = null;

      await service().syncIfNeeded(now: today);

      check(bridge.envelopes).length.equals(1);
      final WidgetSnapshotEnvelope<Object> envelope = bridge.envelopes.single;
      check(envelope.widgetType).equals(IslamicWidgetType.wird);
      check(
        envelope.schemaVersion,
      ).equals(WirdProgressWidgetPayload.currentSchemaVersion);

      final WirdProgressWidgetPayload payload = payloadOf(0);
      check(payload.action).equals(WirdWidgetAction.createPlan);
      check(payload.textDirection).equals(WirdWidgetTextDirection.ltr);
      check(payload.progressValue).equals(0);
      // validUntil drives native staleness and must mirror the payload expiry.
      check(envelope.validUntil).equals(payload.expiresAt);
    });

    test('dedups when nothing the user sees changed', () async {
      prefs.store[LanguageConfig.languageKey] = 'en';
      repository.plan = null;
      final WirdProgressWidgetSyncService sync = service();

      await sync.syncIfNeeded(now: today);
      await sync.syncIfNeeded(now: today.add(const Duration(hours: 3)));

      check(bridge.envelopes).length.equals(1);
    });

    test("republishes when the day's progress changes", () async {
      prefs.store[LanguageConfig.languageKey] = 'en';
      final WirdProgressWidgetSyncService sync = service();

      repository.plan = activePlan();
      await sync.syncIfNeeded(now: today);

      repository.plan = activePlan(currentPage: 6, withProgress: true);
      await sync.syncIfNeeded(now: today);

      check(bridge.envelopes).length.equals(2);
      check(payloadOf(0).formattedCompletedAmount).equals('0');
      check(payloadOf(1).formattedCompletedAmount).equals('5');
    });

    test('keeps the last snapshot when the summary is unreadable', () async {
      repository.throwOnRead = true;

      // Must not throw, and must not dispatch.
      await service().syncIfNeeded(now: today);
      check(bridge.envelopes).isEmpty();

      // No dedup signature was stamped, so recovery still publishes.
      repository
        ..throwOnRead = false
        ..plan = null;
      await service().syncIfNeeded(now: today);
      check(bridge.envelopes).length.equals(1);
    });

    test('shapes digits from the locale, not text direction', () async {
      prefs.store[LanguageConfig.languageKey] = 'ar';
      repository.plan = activePlan();

      await service().syncIfNeeded(now: today);

      final WirdProgressWidgetPayload payload = payloadOf(0);
      check(payload.textDirection).equals(WirdWidgetTextDirection.rtl);
      check(payload.action).equals(WirdWidgetAction.openTodayWird);
      // 21 assigned pages → Arabic-Indic digits.
      check(payload.formattedAssignedAmount).equals('٢١');
    });
  });
}
