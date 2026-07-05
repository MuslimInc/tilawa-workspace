# Quran Sessions — Admin-controlled pricing plan

Status: proposed (2026-07-05). Server quote API and student booking price UX
shipped; this plan covers the remaining Admin Panel work.

## Current state (audited)

- **Pricing source of truth**: `quran_session_market_configs/{countryCode}`
  Firestore docs. `minSessionPrice` (0 = free market), `currencyCode`,
  `isEnabled`, optional per-city overrides, optional `activePolicyVersion`
  pointing into the `policy_versions/{version}` subcollection with
  `effectiveFrom` scheduling. Resolved server-side by
  `functions/src/quranSessions/sessionPolicyResolver.ts`.
- **Admin Panel (`apps/tilawa_admin`)**: has a `quran-sessions` feature area
  (sessions, teachers, disputes, wallets…) but **no market/pricing editor**.
  Pricing is currently edited only via the Firestore console — exactly the
  "hidden/implicit config" problem.
- **Write access**: `firestore.rules` allows public read of market configs and
  denies all client writes. Any admin editor must therefore write through an
  admin-only callable (consistent with the repo rule that high-integrity
  writes live in Cloud Functions).
- **Known drift bug (fix with this work)**: the server reads city overrides
  from a `cities` **array field** on the market doc
  (`sessionPolicyResolver.resolveCityFee`), while the mobile client reads the
  `cities` **subcollection** (`FirestoreMarketConfigDataSource`) and drops
  `minSessionPrice` when mapping city DTOs. The new `getBookingPricingQuote`
  callable makes the server authoritative for the booking flow, but catalog
  surfaces still read the subcollection. Unify on the **subcollection** (it
  has rules and pagination) and migrate the server resolver to read it.

## Proposed Admin Panel feature: "Market pricing"

New page under `apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/`:

- Country list (from `quran_session_market_configs`), each row showing
  enabled state, pricing type (free / fixed), amount + currency, active
  policy version.
- Edit form per country:
  - `isEnabled` (toggle) — market on/off.
  - `pricingType` (radio: **Free** / **Fixed per session**). Free writes
    `minSessionPrice: 0`; fixed requires `minSessionPrice > 0`.
  - `minSessionPrice` (number, validated ≥ 0) + `currencyCode`
    (select: EGP / SAR / USD…).
  - Per-city overrides table (cityId, enabled, optional price override).
  - Optional scheduling: "apply from" date → writes a new
    `policy_versions/{vN}` doc with `effectiveFrom` and sets
    `activePolicyVersion` (structure already supported by the resolver).
- Read path: direct Firestore reads (already publicly readable).
- Write path: new admin callable `updateMarketPricingConfig`:
  - `requireAdmin` guard (same as `postWalletCredit`).
  - Validates with the existing `validateMarketConfigForBooking` before
    writing (fail closed — an admin cannot save a config booking would
    reject).
  - Appends an audit event (`quran_session_events`, action
    `update_market_pricing`, actorRole `admin`) so pricing changes are
    traceable.
- Payment provider status: show a read-only banner "Payment provider:
  disabled — paid bookings are blocked for students" sourced from a small
  `getPlatformPaymentStatus` admin callable wrapping
  `isPaymentProviderEnabled()`, so admins see the consequence of setting a
  paid price while the gate is off.

## Firestore structure (no schema change needed)

```
quran_session_market_configs/{countryCode}
  isEnabled: bool
  minSessionPrice: number        // 0 = free market
  currencyCode: string           // ISO 4217
  activePolicyVersion?: string
  policyEffectiveFrom?: Timestamp
  cities/{cityId}                // subcollection — unify server on this
    isEnabled: bool
    minSessionPrice?: number     // per-city override
  policy_versions/{version}
    effectiveFrom: Timestamp
    minSessionPrice?, currencyCode?, cities?…   // overlay fields
```

## Follow-ups

1. Unify city override source (subcollection) between
   `sessionPolicyResolver.ts` and the client catalog data source; include
   `minSessionPrice` in the client city DTO mapping.
2. `updateMarketPricingConfig` callable + rules-parity tests.
3. Angular market-pricing page + facade + mapper specs.
4. When a real payment provider lands, replace the env gate with per-market
   provider config surfaced on the same admin page.
