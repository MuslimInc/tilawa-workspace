# Contract B (presentation): Wird Progress Widget Payload — owned by Spec 041

**Status**: Proposed (documentation only)
**Version**: 1.0.0 · `schemaVersion: 1`
**Layer**: Presentation. Produced by a **Spec 041 adapter** from the Spec 023 semantic
summary (`specs/023-smart-khatma-reading-plan/contracts/wird-progress-summary.md`).

> Separation of concerns: Spec 023 owns **meaning** (Contract A, semantic, locale-free).
> Spec 041 owns **presentation** (this contract, localized + formatted). The adapter is the
> only place localization and digit formatting happen. The native widget renders this payload
> verbatim and never recomputes plan math.

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
  "deepLink": "tilawa://khatma",
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
| `deepLink` | string(URI) | ✓ | Concrete route resolved from the semantic `tapDestination`. |
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
`none` (start CTA) · `active` · `paused` · `completed-day` · `completed-plan` · `offline`
(persisted payload) · `stale` (past `expiresAt` → last-known + subtle cue). Mapped from the
semantic `planStatus`/`adherenceState` by the adapter.

## Invariants
- The widget renders this payload **verbatim**; it performs no localization, formatting, or
  plan math. All of that is the adapter's responsibility (Spec 041).
- Unknown `schemaVersion` major → render the setup/no-data state, never crash.
- Only display-ready strings + progress cross into native code — no raw history.
