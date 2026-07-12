# Contract A (semantic): Wird / Khatma Progress Summary — owned by Spec 023

**Status**: Proposed (documentation only)
**Version**: 1.0.0 · `schemaVersion: 1`
**Privacy Classification**: Low-sensitivity (day/aggregate only; no per-ayah reading log)
**Layer**: Domain/application. **Locale-independent and presentation-independent.**

> This is the **semantic** contract. It carries *meaning and numbers only* — **no localized
> strings, no formatted digits, no colors, no text direction**. The widget layer (Spec 041)
> derives a separate presentation payload from it (Contract B:
> `specs/041-islamic-widget-suite/contracts/wird-progress-widget-payload.md`).

## Ownership
- **Spec 023 (Smart Khatma) PRODUCES** this summary from the plan domain
  (`get_khatma_today_target_use_case` + adherence from 023-A2). Single source of truth.
- **Spec 041 (Widget Suite) CONSUMES** it via a **presentation adapter** that maps it to the
  `WirdProgressWidgetPayload` (localized/formatted), then hands *that* to the native widget
  over the existing bridge (`specs/041-islamic-widget-suite/contracts/widget-bridge.md`).
- **Spec 043 (Trust)** contributes **only** integrity primitives (correct page/Juz boundary
  data the plan relies on). It neither produces nor renders this summary.

## Schema (semantic — no presentation fields)
```json
{
  "schemaVersion": 1,
  "planId": "local_2026-06-15T09:00:00.000",
  "planStatus": "active",
  "localPlanDate": "2026-07-12",
  "targetType": "pages",
  "assignedAmount": 20,
  "completedAmount": 12,
  "remainingAmount": 8,
  "completionRatio": 0.60,
  "adherenceState": {"daysCommitted": 5, "bestRun": 9, "state": "on_track"},
  "tapDestination": "openKhatma",
  "lastUpdatedAt": "2026-07-12T09:14:00.000Z",
  "isStale": false
}
```

## Fields
| Field | Type | Req | Notes |
|---|---|---|---|
| `schemaVersion` | int | ✓ | Consumer rejects unknown major; ignores unknown fields. |
| `planId` | string | ✓ | Local/anonymous id — **never** a user account id. |
| `planStatus` | enum | ✓ | `active` \| `paused` \| `completed` \| `none`. |
| `localPlanDate` | string(YYYY-MM-DD) | ✓ | Local calendar day the summary applies to. |
| `targetType` | enum | ✓ | `pages` \| `minutes` (mirrors `KhatmaReadingStyle`). Unit token, **not** a localized word. |
| `assignedAmount` | int | ✓ | Today's target in `targetType` units. `0` when completed/none. **Raw number, unformatted.** |
| `completedAmount` | int | ✓ | Amount done today. **Raw number.** |
| `remainingAmount` | int | ✓ | `max(0, assigned − completed)`. **Raw number.** |
| `completionRatio` | double 0–1 | ✓ | Today's ratio; clamp. |
| `adherenceState` | object | ✓ | `{ daysCommitted:int, bestRun:int, state: on_track\|behind\|paused\|none }`. Calm semantics (023-A2); no punitive fields. |
| `tapDestination` | enum | ✓ | **Semantic intent** `openKhatma`\|`openReader`\|`openWidgetSetup` (not a URL). 041 maps it to a concrete deep link. |
| `lastUpdatedAt` | string(ISO-8601 UTC) | ✓ | When 023 produced the summary. |
| `isStale` | bool | ✓ | Producer hint; widget also derives staleness from envelope `validUntil`. |

## MUST NOT contain (belongs to Contract B, Spec 041)
`displayLabelAr`, `displayLabelEn`, any localized title/subtitle, formatted digits
(Arabic-Indic vs Latin), text direction, colors, accessibility strings, or concrete deep-link URLs.

## Semantic states (meaning only; rendering is 041's job)
- `planStatus:none` → no active plan (widget shows a start CTA).
- `active` → assigned/completed/remaining + ratio meaningful.
- `paused` → adherence frozen; no missed-day accrual.
- `completed` (`remainingAmount:0`) → day or plan complete.

## Invariants
- One-way producer output; 041 never writes back to it. Actions return only as the semantic
  `tapDestination` intents.
- **No sensitive reading history**: only day/aggregate numbers cross the boundary — never a
  list of read ayat, timestamps, or precise history.

## Versioning
- Additive fields → same major, consumer ignores unknowns.
- Breaking change → bump `schemaVersion`; consumer renders its no-data/setup state for an
  unknown major (never crashes, never guesses).
