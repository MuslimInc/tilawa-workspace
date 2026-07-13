# Amendment: Daily Wird / Khatma Progress Widget (041-A1)

**Status**: Proposed (documentation only — do not implement yet)
**Parent**: `specs/041-islamic-widget-suite/spec.md`
**Source evidence**: Khatmah review sample — **K48** (upvoted: "add widgets concerning the
main topic… Khatmas (daily readings)… a must") and **K51** (adherence-days). This is the
**strongest currently unowned retention opportunity observed in this extremes-only sample**;
it is **not** a total-market-demand estimate.

## Why this amendment
Spec 041 (verified in repo) ships **Prayer** (US1, `PrayerTimesWidgetProvider.kt`), **Ayah of
the Day** (US2, `widget/ayah/`), and **Athkar** (US3, `widget/athkar/`); **Hijri** (US4) and
**Share cards** (US5) are pending. Widget types are `IslamicWidgetType { prayer, ayah, athkar,
hijri }` — **there is no Khatma/Wird-progress widget.** Yet the central app habit (Spec 023
Khatma/Wird) has no glanceable home-screen surface. This amendment adds exactly one widget to
close that gap, reusing the shipped widget foundation (`WidgetSnapshotEnvelope`,
`WidgetSnapshotStore.kt`, `widget_snapshot_bridge.dart`, deep-link routing).

## Platform phasing (accurate — no false parity promise)
Repository audit: **no iOS WidgetKit foundation exists** — no widget extension target, no
`TimelineProvider`, and **no App Group entitlement** (grep of `apps/tilawa/ios` finds only
Pods/Firebase/Agora "extension" dirs, none app-owned). Therefore:

- **Phase 1 — Android (this amendment).** Build the Wird widget on the **existing, shipped**
  Android widget infrastructure (`WidgetSnapshotStore.kt`, `widget_snapshot_bridge.dart`,
  providers under `widget/`). Reuses the battery-safe refresh cadence — **no new scheduling
  engine, no per-second updates**. This is the only platform in scope here.
- **Phase 2 — iOS (future child specification, NOT a task in this slice).** iOS requires
  foundations that do not exist yet and must be audited/built first: a WidgetKit extension
  target, **App Group** shared storage, a `TimelineProvider`, shared snapshot serialization,
  deep-link handling, localization, and build/provisioning (signing, entitlements). Because
  none of this exists, iOS is filed as a **future child spec** (`041-ios-widgetkit-foundation`,
  TBD), not an unchecked task inside the Android slice. Product **semantics** stay identical
  across platforms (same Contract A summary); **technical parity is not promised** for v1.

Consistent semantics, honestly phased delivery: same meaning both platforms, Android first.

## Requirements
- **FR-041A1.1**: Add widget type `wird` (extend `IslamicWidgetType`) with a launcher picker
  preview. It renders the **Wird/Khatma progress summary** only.
- **FR-041A1.2**: A **Spec 041 presentation adapter** MUST consume the **semantic summary**
  (Contract A, `specs/023-smart-khatma-reading-plan/contracts/wird-progress-summary.md`) and
  produce the **`WirdProgressWidgetPayload`** (Contract B,
  `specs/041-islamic-widget-suite/contracts/wird-progress-widget-payload.md`), which is handed
  to the native provider over the existing bridge (`widgetType: "wird"`). The widget MUST NOT
  compute plan math, page targets, or adherence (Spec 023 owns those). **No duplicate progress
  logic in the widget.**
- **FR-041A1.3**: The **adapter** (not Spec 023) localizes and formats: it produces
  `localizedTitle`/`localizedSubtitle`, formatted digit strings, and the `accessibilityLabel`.
  Digit shaping (Arabic-Indic vs Latin) is chosen from **locale + user numeral preference, not
  text direction alone**. The native widget renders the payload verbatim.
- **FR-041A1.4**: MUST handle every state from the contract: **no-plan** (Start-a-Wird CTA),
  **active**, **paused**, **completed-day**, **completed-plan**, **offline**, **stale** — and
  MUST never show a blank frame (reuse the suite's last-known-data + staleness rule, FR-014).
- **FR-041A1.5**: Tap MUST deep-link per `tapDestination` (`openKhatma` default) via a new
  allowed action `openKhatma` added to the widget-bridge action set.
- **FR-041A1.6**: MUST offer light/dark/auto themes and ≥2 size classes consistent with design
  tokens (suite FR-009); MUST expose accessibility labels and remain legible at 200% text
  scale (suite FR-015); MUST render correctly in **Arabic RTL** and **English LTR**.
- **FR-041A1.7**: MUST survive reboot/launcher-restart/app-update by re-rendering from the
  persisted snapshot without opening the app (suite FR-010).
- **FR-041A1.8**: Privacy — the payload carries only day/aggregate numbers + pre-rendered
  labels (never a reading-history list); analytics identify widget type/interaction only
  (suite FR-016). On lock-screen/at-a-glance surfaces, no sensitive history is exposed.
- **FR-041A1.9**: Payload is **versioned** (`schemaVersion`); an unknown major version renders
  the no-data/setup state, never a crash.

## Data contracts (two — semantic vs presentation)
- **Contract A (semantic, owned by Spec 023)**: `wird-progress-summary.md` v1 — meaning/numbers
  only, locale-free. Consumed here.
- **Contract B (presentation, owned by Spec 041)**: `contracts/wird-progress-widget-payload.md`
  v1 — localized + formatted, produced by the 041 adapter and rendered verbatim by the native
  widget. This amendment **owns Contract B and the adapter**; it does not own plan math.

## Analytics (privacy-safe, reuse `widget_analytics.dart`)
`widget_added`/`widget_removed` (type=`wird`), `widget_tapped` (type=`wird`), and a
`wird_widget_state_rendered` { `state` } for coverage of the no-plan/active/stale paths.

## Tasks (not implemented — Phase 1 Android only)
- [x] T-041A1-a: Extend `IslamicWidgetType` with `wird`; give `WirdProgressWidgetPayload`
  a versioned Dart parse path (`fromJson`/`tryParse`) symmetric to `toJson`. Unknown
  `schemaVersion` major or malformed fields → setup state (`null`), never a crash
  (FR-041A1.9). Native envelope decode (Kotlin) remains part of T-041A1-c.
- [x] T-041A1-b: **Presentation adapter** (Contract A → Contract B): localize, format digits by
  locale/preference, build accessibility label, and pass through the semantic action. Concrete
  route resolution remains T-041A1-d with the native action allow-list.
- [ ] T-041A1-c: Native `WirdProgressWidgetProvider.kt` (compact/expanded, states, deep link) under `widget/wird/`.
  - [x] **Decode half**: `WidgetType.WIRD` + `widget/wird/WirdProgressWidgetPayload.kt` — a Kotlin
    data class with a tolerant `parse(JSONObject)` mirroring the Flutter `tryParse` (unknown
    action/text-direction, out-of-range progress, or blank required field → `null` → setup
    state; timestamps stay envelope-owned). The versioned `WidgetSnapshotEnvelope` +
    `WidgetSnapshotStore` now round-trip `wird` snapshots. Robolectric-tested.
  - [ ] **Render half** (not in this slice): provider class, compact/expanded layouts, per-state
    rendering, deep-link/click intents, and AndroidManifest registration.
- [ ] T-041A1-d: Add `openKhatma` to allowed widget actions + router destination.
- [x] T-041A1-e: **Flutter sync service** (`WirdProgressWidgetSyncService`) composes
  `GetWirdProgressSummaryUseCase` → adapter → `WidgetSnapshotEnvelope(widgetType:"wird")` →
  `WidgetSnapshotBridge`. Locale + numeral system resolved from `LanguageConfig`; content-
  signature dedup allows intra-day updates while skipping no-op relaunches; best-effort
  (failure keeps the last snapshot, FR-041A1.4). The startup trigger + `enable_wird_widget`
  gate are wired with the native provider (T-041A1-c/-f), so no live publish ships before a
  native consumer exists.
- [ ] T-041A1-f: Layouts/resources/previews + AndroidManifest registration.
- [ ] *(Phase 2 iOS — deferred to future child spec `041-ios-widgetkit-foundation`; not tasked here.)*

## Tests
- Domain/parse: envelope `wird` payload parse; unknown-version → setup state. ✅ Dart coverage
  in `test/features/islamic_widgets/domain/wird_progress_widget_payload_test.dart` and
  `test/features/islamic_widgets/data/wird_widget_snapshot_bridge_test.dart`; native decode
  parity landed in `android/.../widget/wird/WirdProgressWidgetPayloadTest.kt` (Robolectric).
- Native decode (Robolectric): `WirdProgressWidgetPayloadTest` (complete parse, reject bad
  action/text-direction/progress/blank) + `WidgetSnapshotStoreTest` wird envelope round-trip. ✅
- Native render (Robolectric, pending render half): each contract state renders non-blank; deep link fires; resize no-clip.
- RTL/LTR + 200% text-scale + light/dark golden coverage.
- Offline/stale: renders persisted snapshot; staleness cue appears past `validUntil`.
- Producer path: `WirdProgressWidgetSyncService` dispatches a `wird` envelope, dedups unchanged
  state, re-publishes on progress change, shapes digits by locale, and keeps the last snapshot
  on summary failure. ✅ `test/features/islamic_widgets/app/wird_progress_widget_sync_service_test.dart`.

## Manual QA
- Xiaomi/Redmi + Samsung (Egypt OEMs): place widget, complete Wird in-app, confirm widget
  reflects new remaining within one refresh; reboot → non-blank; airplane mode → last-known.

## Rollout & fallback
- Feature-flag `enable_wird_widget` (default off) → staged. If the 023 summary is unavailable
  (flag off or no plan), the widget shows the **no-plan CTA**, never an error. The Spec 023
  summary source is now available (`GetWirdProgressSummaryUseCase`, wired in
  `SmartKhatmaDependencies`), so the producer (T-041A1-e) is unblocked; the staged flag and the
  native startup trigger gate the live publish.

## Non-goals
- iOS widget (v1 Android-only), lock-screen variant, share-card of progress, any plan editing
  from the widget, and any progress computation inside the widget.
