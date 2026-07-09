# Data Model: Learn Quran Admin and Backend Completion

## Global platform configuration

**Owner**: `quran_session_platform_config/global` through
`updatePlatformConfig`.

| Field group | Purpose | Plan treatment |
|---|---|---|
| rollout flags | Master, student-entry, and booking availability | Existing validated admin fields. |
| `childAgeThreshold` | Eligibility age policy | Must round-trip instead of receiving an unintended fallback. |
| delivery/booking policy | `videoOnly`, booking mode, schedule defaults | Preserve validated platform contract. |
| market and teacher-entry gates | Market eligibility and teacher application controls | Existing validated admin fields. |

## Market configuration

**Owner**: `quran_session_market_configs/{countryCode}` and city subdocuments
through `updateMarketPricingConfig`.

| Field group | Purpose | Plan treatment |
|---|---|---|
| availability/pricing | Country, enabled state, currency, price | Existing editable validated values. |
| scheduling/eligibility | Booking mode, notice, windows, limits, matching, whitelist | Existing editable validated values. |
| payment instructions | Provider/manual flags and instructions | Existing validated values; paid expansion excluded. |
| city overrides | City enabled state and minimum price | Existing bounded override list. |
| delivery mode | Video-only capability | Fixed display; not submitted as a market field. |

## Session report

**Owner**: `quran_session_reports/{reportId}` through report callables.

| Attribute | Meaning |
|---|---|
| identity/context | Report, booking, session, aggregate, reporter, and optional reported-user IDs. |
| classification | Category plus derived normal/high severity. |
| state | `open`, `under_review`, `resolved`, or `dismissed`. |
| terminal metadata | Resolution reason, administrator, and time. |

```text
open → under_review
open | under_review → resolved | dismissed (reason required)
resolved | dismissed → terminal/read-only
```

## Session dispute

**Owner**: `quran_session_disputes/{disputeId}` and the related booking through
dispute callables.

| Attribute | Meaning |
|---|---|
| identity/context | Dispute, aggregate, booking, session, opener, and reason. |
| resolution | `favor_student`, `favor_teacher`, `with_compensation`, `rejected`, or `closed`. |
| terminal metadata | Reason, administrator, time, and possible refund/compensation ID. |

The server resolves only a currently disputed booking and is idempotent; UI
retry must not create duplicate effects.

## Data migration

No collection or migration is planned. Legacy global documents can continue to
use the backend fallback until an administrator saves a deliberate age value.

