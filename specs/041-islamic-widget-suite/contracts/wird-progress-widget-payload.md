# Contract B (presentation): Wird Progress Widget Payload — owned by Spec 041

**Status**: Proposed (documentation only)
**Version**: 1.0.0 · `schemaVersion: 1`
**Layer**: Presentation. Produced by a **Spec 041 adapter** from the Spec 023 semantic
summary (`specs/023-smart-khatma-reading-plan/contracts/wird-progress-summary.md`).

> Separation of concerns: Spec 023 owns **meaning** (Contract A, semantic, locale-free).
> Spec 041 owns **presentation** (this contract, localized + formatted). The adapter is the
> only place localization and digit formatting happen. The native widget renders this payload
> verbatim and never recomputes plan math.

**Release disposition:** optional and default-off. Widget rollout does not
block the core Flutter Al-Khatmah release and must consume confirmed-progress
summaries only.

## Production path
```
KhatmaPlan domain (023)
  → WirdProgressSummary (Contract A, semantic)     [produced by 023]
  → [041 adapter: localize + format + resolve deep link]
  → WirdProgressWidgetPayload (Contract B, this)   [produced by 041]
  → WidgetSnapshotEnvelope(widgetType:"wird")      [existing bridge]
  → native WirdProgressWidgetProvider              [renders verbatim]
```

## Schema (presentation — localized & formatted)
```json
{
  "schemaVersion": 1,
  "locale": "ar",
  "textDirection": "rtl",
  "localizedTitle": "وِرد اليوم",
  "localizedSubtitle": "٨ صفحات متبقية من ٢٠",
  "formattedAssignedAmount": "٢٠",
  "formattedCompletedAmount": "١٢",
  "formattedRemainingAmount": "٨",
  "progressValue": 0.60,
  "accessibilityLabel": "ورد اليوم، أُنجز ١٢ من ٢٠ صفحة، بقي ٨",
  "action": "openTodayWird",
  "generatedAt": "2026-07-12T09:14:00.000Z",
  "expiresAt": "2026-07-13T00:00:00.000Z",
  "isStale": false
}
```

## Fields
| Field | Type | Req | Notes |
|---|---|---|---|
| `schemaVersion` | int | ✓ | Presentation contract version. |
| `locale` | string(BCP-47) | ✓ | Resolved from the device/in-app language setting. |
| `textDirection` | enum | ✓ | `rtl` \| `ltr`, derived from `locale`. |
| `localizedTitle` | string | ✓ | e.g. "وِرد اليوم" / "Today's Wird". |
| `localizedSubtitle` | string | ✓ | e.g. "٨ صفحات متبقية" / "8 pages left". |
| `formattedAssignedAmount` | string | ✓ | Digits formatted per locale+user prefs (see below). |
| `formattedCompletedAmount` | string | ✓ | Same. |
| `formattedRemainingAmount` | string | ✓ | Same. |
| `progressValue` | double 0–1 | ✓ | Passed through from `completionRatio`. |
| `accessibilityLabel` | string | ✓ | Full spoken description; ordered for the locale. |
| `action` | enum | ✓ | Semantic action passed through from Spec 023: `createPlan` \| `openTodayWird` \| `viewCompletedPlan`. Native routing is deliberately deferred. |
| `generatedAt` | string(ISO-8601) | ✓ | When the adapter produced this payload. |
| `expiresAt` | string(ISO-8601) | ✓ | Maps to envelope `validUntil`; drives staleness. |
| `isStale` | bool | ✓ | Passed through / re-derived at render. |

## Digit formatting rule (explicit)
Digit shaping (Arabic-Indic `٠١٢…` vs Latin `012…`), grouping, and numeral system are chosen
from the **user's locale and any in-app numeral preference — NOT from text direction alone.**
An RTL layout does not by itself imply Arabic-Indic digits (e.g. an RTL locale may still prefer
Latin digits). The adapter resolves numerals via the locale/preference; the native widget never
reformats numbers.

## Rendering states (native widget MUST handle, non-blank always)
`none` (start CTA) · `active` · `completed-day` · `completed-plan` · `offline`
(persisted payload) · `stale` (past `expiresAt` → last-known + subtle cue). Mapped from the
semantic `planStatus` and daily amounts by the adapter.

## Invariants
- The widget renders this payload **verbatim**; it performs no localization, formatting, or
  plan math. All of that is the adapter's responsibility (Spec 041).
- Unknown `schemaVersion` major → render the setup/no-data state, never crash.
- Only display-ready strings + progress cross into native code — no raw history.

## Implemented boundary

- Payload: `features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart`.
- Adapter: `features/islamic_widgets/presentation/adapters/wird_progress_widget_adapter.dart`.
- Schema v1 follows finalized Spec 023: pages only; `none`, `active`, and `completed`; no
  paused, minute, or adherence fields.
- Numeral shaping is an explicit adapter input and remains independent of text direction.
- `IslamicWidgetType` now carries `wird`, and the payload has a versioned Dart parse path
  (`WirdProgressWidgetPayload.fromJson` strict / `tryParse` tolerant) symmetric to `toJson`.
  `tryParse` returns `null` (→ setup/no-data state) for an unknown `schemaVersion` major or any
  malformed field, never crashing — the Dart-side executable reference for the version invariant
  above.
- Producer: `features/islamic_widgets/app/wird_progress_widget_sync_service.dart` composes the
  Spec 023 summary → adapter → `WidgetSnapshotEnvelope(widgetType:"wird")` and dispatches it via
  the existing `WidgetSnapshotBridge`. Locale + numeral system come from `LanguageConfig` (no
  in-app numeral preference exists yet, so the locale drives digit shaping). A content signature
  dedups unchanged relaunches while allowing intra-day updates; failures keep the last snapshot.
- Native decoder: `android/.../widget/wird/WirdProgressWidgetPayload.kt` mirrors the Flutter
  tolerant parser (unknown action/text-direction, out-of-range progress, or blank required field
  → `null` → setup state; `generatedAt`/`expiresAt`/`isStale` stay envelope-owned and are
  re-derived at render). `WidgetType.WIRD` was added, so the versioned `WidgetSnapshotEnvelope`
  and `WidgetSnapshotStore` now decode and persist `wird` snapshots. Robolectric-tested.
- Still out of scope here (the native **render half**): the `WirdProgressWidgetProvider` class,
  compact/expanded layouts, per-state rendering, deep-link/click intents, AndroidManifest
  registration, the startup trigger + staged `enable_wird_widget` flag, and the `openKhatma`
  route resolution. Decode and persistence exist, but nothing renders or auto-activates yet.
