# Backend / Cloud Functions — Learn Quran (Quran Sessions)

**Scope:** Free 1:1 **video-only** beta. Backend is the single source of truth
for pricing, eligibility, bookability, and rollout config.

**Completion (evidence-based): ~90%**
**Verdict: READY (with non-blocking follow-ups)**

---

## Source-of-truth architecture (verified)

- `loadBookingEligibilityContext(db, uid, teacherId)` is the shared resolver used
  by **all** of:
  - `getBookingPricingQuote` (student preview — price + typed `blockReason`),
  - `createSessionBooking` (authoritative enforcement),
  - `getResolvedSessionConfig` (admin inspector).
  This is why teacher list, teacher profile, booking screen, and Admin Panel
  **cannot disagree** on effective price, pricing source, bookable status, or
  block reason.
- Rollout config lives in `quran_session_platform_config/global` and is written
  only by admin-claim callables (`updatePlatformConfig`), read by the app via
  `QuranSessionsPlatformConfigStore` (fails closed).

## Pricing quote (verified)

- `buildPricingQuote` / `resolveBlockReasonWithTeacher` return a **typed**
  `blockReason` inside a *successful* response for config-level blocks
  (`bookingDisabledByAdmin`, `marketDisabled`, `teacherNotBookable`,
  `pricingConfigMissing`) and for `paymentProviderUnavailable` (paid while the
  payment gate is off). Auth/epoch/transport errors still throw.
- Free vs paid resolved from `ctx.pricing.isPaid`; teacher-level override honored
  (`effectivePricingSource: teacherOverride | marketConfig | platformFallback`).
- Business rule guaranteed server-side: **paid + payment provider disabled →
  `paymentProviderUnavailable`**; the client hides/blocks accordingly.

## What changed in this pass

- `updatePlatformConfig`: now accepts + **validates** + persists tutor-entry
  fields (`teacherApplicationEnabled`, `teacherApplicationEntryEnabled`,
  `homeTeacherApplicationCardEnabled`, `teacherApplicationDiscoverability`).
  `{merge:true}` preserves omitted fields; discoverability constrained to
  `none|profileOnly|profileAndEmptyState`; booleans type-checked when provided.
  Event log mirrors the change.

## Checklist

- [x] Shared eligibility/pricing resolver across preview + booking + admin
- [x] Typed `BookingBlockReason` (server → client), no boolean inference
- [x] Teacher-level free override honored in resolution
- [x] Admin-writable rollout config (incl. tutor entry, this change)
- [x] Video-only enforced (`sessionMode: videoOnly`; paid/group/RTC callables rejected)
- [x] App Check + session-epoch guards on callables
- [ ] **Batch** `getBookingPricingQuotes(teacherIds[])` to remove the client
      N+1 on teacher-list load (non-blocking; see below)

## N+1 pricing quote (non-blocking follow-up)

The teacher list now fetches one `getBookingPricingQuote` **per teacher** (needed
for correctness — price/blockReason vary per teacher via overrides/whitelist).
Each call re-runs `loadBookingEligibilityContext` (student + market + teacher +
policy reads). Fine for a curated beta (5–15 teachers). Before large-market
rollout, add a batch callable that resolves shared student/market/platform
context once and varies only per-teacher lookups.

## Launch blockers

- **Deploy** the Quran Sessions callable batch (incl. updated
  `updatePlatformConfig`, `createSessionBooking`, `registerActiveDevice`) to the
  target Firebase project (ops).
- Flip App Check enforcement on staging/prod per runbook (ops).

## Manual QA / verification checklist

- [ ] `getBookingPricingQuote` returns `blockReason: paymentProviderUnavailable`
      for a paid teacher while payment gate is off.
- [ ] `getResolvedSessionConfig` matches the app's rendered price/bookable state.
- [ ] `updatePlatformConfig` persists tutor-entry fields and rejects invalid input.

## Automated test coverage

- `functions` unit suite: **388 passed / 0 failed** (`node --test`), including
  `getBookingPricingQuote.test.ts` and `updatePlatformConfig.test.ts` (+3 new).
- Emulator integration + rules suites exist (`test:integration`, `test:rules`) —
  run under Firebase emulator (JDK 21) in CI; not re-run in this pass.
