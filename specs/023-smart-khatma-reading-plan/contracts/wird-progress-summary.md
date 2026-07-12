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
  "adjustment": "none",
  "action": "openTodayWird"
}
```

## Fields
| Field | Type | Req | Notes |
|---|---|---|---|
| `schemaVersion` | int | ✓ | Consumer rejects unknown major; ignores unknown fields. |
| `planId` | string | ✓ | Local/anonymous id — **never** a user account id. |
| `planStatus` | enum | ✓ | `active` \| `completed` \| `none`. `paused` is reserved for a future breaking/additive contract revision and is not valid in schema v1. |
| `localPlanDate` | string(YYYY-MM-DD) | ✓ | Local calendar day the summary applies to. |
| `targetType` | enum | ✓ | `pages`. Minute plans have no verified progress source and fail production in schema v1 rather than mixing units. |
| `assignedAmount` | int | ✓ | Today's target in `targetType` units. `0` when completed/none. **Raw number, unformatted.** |
| `completedAmount` | int | ✓ | Amount done today. **Raw number.** |
| `remainingAmount` | int | ✓ | `max(0, assigned − completed)`. **Raw number.** |
| `completionRatio` | double 0–1 | ✓ | Today's ratio; clamp. |
| `adjustment` | enum | ✓ | `none` \| `automaticCatchUp` \| `catchUp` \| `extended`. Explicit choices are exposed only on the local day selected. |
| `action` | enum | ✓ | `createPlan` \| `openTodayWird` \| `viewCompletedPlan`. Semantic intent only, never a route. |

## MUST NOT contain (belongs to Contract B, Spec 041)
`displayLabelAr`, `displayLabelEn`, any localized title/subtitle, formatted digits
(Arabic-Indic vs Latin), text direction, colors, accessibility strings, or concrete deep-link URLs.

## Semantic states (meaning only; rendering is 041's job)
- `planStatus:none` → no active plan (widget shows a start CTA).
- `active` → assigned/completed/remaining + ratio meaningful.
- `completed` (`remainingAmount:0`) → day or plan complete.

## Daily checkpoint lifecycle

`KhatmaPlan.progressDate` is the local civil date of the current checkpoint and
`progressStartPage` is the verified plan page immediately before that day's first accepted
forward page advancement. `UpdateKhatmaProgressUseCase` initializes both fields before applying
that advancement, preserves them across later same-day updates, and replaces them on the first
accepted advancement of another local civil date. Summary reads never initialize or persist a
checkpoint. Legacy plans without either field remain valid and report zero completed today until
their next accepted advancement.

The local plan day is the device-local civil date (`year-month-day`) supplied by the injected
clock at the moment of the operation. The privacy-safe plan ID uses the persisted local creation
token verbatim; it is not converted, hashed, or regenerated during summary reads.

`KhatmaPlan.adjustment` records the last selected strategy and `adjustmentDate` records its local
civil day. The semantic summary exposes an explicit catch-up/extend choice only when that date
matches `localPlanDate`; older metadata is historical and maps to `none`. Automatic catch-up is
derived from current page debt.

## Invariants
- One-way producer output; 041 never writes back to it. Actions return only as the semantic
  `tapDestination` intents.
- **No sensitive reading history**: only day/aggregate numbers cross the boundary — never a
  list of read ayat, timestamps, or precise history.

## Versioning
- Additive fields → same major, consumer ignores unknowns.
- Breaking change → bump `schemaVersion`; consumer renders its no-data/setup state for an
  unknown major (never crashes, never guesses).
